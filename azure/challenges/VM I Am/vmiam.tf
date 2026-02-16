# resource group
resource "azurerm_resource_group" "vmiam" {
  name      = "vmiamRG"
  location  = var.azure_region
}

data "azurerm_client_config" "current" {}

resource "random_string" "rand" {
  length  = 6
  upper   = false
  numeric  = true
  special = false
}

resource "random_id" "suffix" {
  byte_length = 4
}

data "http" "current_ip" {
  url = "https://icanhazip.com"
}

locals {
  user_ip = chomp(data.http.current_ip.response_body)
}

# Key Vault
resource "azurerm_key_vault" "ctf_kv" {
  name                        = "ctfkv${random_string.rand.id}"
  resource_group_name         = azurerm_resource_group.vmiam.name
  location                    = azurerm_resource_group.vmiam.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  enable_rbac_authorization   = true
}

# Create secret
resource "azurerm_role_assignment" "terraform_admin_rbac" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.ctf_kv.id
}

# Secret(flag)
resource "azurerm_key_vault_secret" "flag" {
  name         = "ctf-flag"
  value        = "FLAG{vmIAm:keyvaultMisconfiguredRead}"
  key_vault_id = azurerm_key_vault.ctf_kv.id

  depends_on = [
    azurerm_role_assignment.terraform_admin_rbac
  ]
}

# Managed Identity
resource "azurerm_user_assigned_identity" "ctf_identity" {
  name                = "ctf-kv-reader-id"
  resource_group_name = azurerm_resource_group.vmiam.name
  location            = azurerm_resource_group.vmiam.location
}

# RBAC
resource "azurerm_role_assignment" "kv_reader" {
  principal_id         = azurerm_user_assigned_identity.ctf_identity.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.ctf_kv.id
}

# VM Network
resource "azurerm_virtual_network" "ctf_vnet" {
  name                = "ctf-vnet"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.vmiam.name
  location            = azurerm_resource_group.vmiam.location
}

resource "azurerm_subnet" "ctf_subnet" {
  name                 = "ctf-subnet"
  resource_group_name  = azurerm_resource_group.vmiam.name
  virtual_network_name = azurerm_virtual_network.ctf_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "ctf_ip" {
  name                = "ctf-public-ip"
  resource_group_name = azurerm_resource_group.vmiam.name
  location            = azurerm_resource_group.vmiam.location
  allocation_method   = "Static"
}

# let user discover the IP
resource "azurerm_role_assignment" "player_ip_reader" {
  scope                = azurerm_public_ip.ctf_ip.id
  role_definition_name = "Reader"
  principal_id         = var.player_object_id
}

resource "azurerm_network_interface" "ctf_nic" {
  name                = "ctf-nic"
  resource_group_name = azurerm_resource_group.vmiam.name
  location            = azurerm_resource_group.vmiam.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ctf_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
    public_ip_address_id          = azurerm_public_ip.ctf_ip.id
  }
}

# let user discover the nic
resource "azurerm_role_assignment" "player_nic_reader" {
  scope                = azurerm_network_interface.ctf_nic.id
  role_definition_name = "Reader"
  principal_id         = var.player_object_id
}

resource "azurerm_network_security_group" "ctf_nsg" {
  name                = "ctf-nsg"
  resource_group_name = azurerm_resource_group.vmiam.name
  location            = azurerm_resource_group.vmiam.location

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.user_ip       
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "ctf_subnet_assoc" {
  subnet_id                 = azurerm_subnet.ctf_subnet.id
  network_security_group_id = azurerm_network_security_group.ctf_nsg.id
}

# VM
resource "azurerm_linux_virtual_machine" "ctf_vm" {
  name                = "ctf-vm"
  resource_group_name = azurerm_resource_group.vmiam.name
  location            = azurerm_resource_group.vmiam.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  disable_password_authentication = false
  admin_password      = "P@ssword1234!"  

  network_interface_ids = [
    azurerm_network_interface.ctf_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.ctf_identity.id]
  }

  custom_data = base64encode(templatefile("${path.module}/data/cloud-init.yaml.tftpl", {
    keyvault_name = azurerm_key_vault.ctf_kv.name
  }))

  depends_on = [
    azurerm_key_vault.ctf_kv
  ]
}

# let user discover the vm
resource "azurerm_role_assignment" "player_vm_reader" {
  scope                = azurerm_linux_virtual_machine.ctf_vm.id
  role_definition_name = "Reader"
  principal_id         = var.player_object_id
}

resource "azurerm_key_vault" "ctf2" {
  name                        = "ctfkv${random_id.suffix.hex}"
  resource_group_name         = azurerm_resource_group.vmiam.name
  location                    = azurerm_resource_group.vmiam.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  enable_rbac_authorization   = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules = [local.user_ip]
  }

}

resource "azurerm_key_vault_secret" "creds" {
  name         = "creds"
  value        = "azureuser:P@ssword1234!"
  key_vault_id = azurerm_key_vault.ctf2.id

  depends_on = [
    azurerm_role_assignment.deploy_kv_admin
  ]
}

resource "azurerm_role_assignment" "kv_reader2" {
  principal_id         = var.player_object_id
  role_definition_name = "Reader"
  scope                = azurerm_key_vault.ctf2.id
}

resource "azurerm_role_assignment" "kv_secrets_reader" {
  principal_id         = var.player_object_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.ctf2.id
}

resource "azurerm_role_assignment" "deploy_kv_admin" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.ctf2.id
}