# resource group
resource "azurerm_resource_group" "cloudjumping" {
  name      = "cloudjumpingRG"
  location  = var.azure_region
}

data "azuread_domains" "domain" {
  only_initial = true
}

data "azurerm_subscription" "current" {}

data "http" "current_ip" {
  url = "https://icanhazip.com"
}

locals {
  user_ip = chomp(data.http.current_ip.response_body)
}

# password for read user
resource "random_password" "read_user_password" {
  length  = 16
  special = true
}

# store creds locally then later upload them to storage account
resource "local_file" "credentials" {
  filename = "${path.module}/data/container/tmp.txt"
  content = <<-EOF
  "az.reader@${data.azuread_domains.domain.domains.0.domain_name}"
  ${random_password.read_user_password.result}
  EOF
}

# create read user and give them global reader
resource "azuread_user" "read_user" {
  user_principal_name = "az.reader@${data.azuread_domains.domain.domains.0.domain_name}"
  display_name        = "Azure Reader"
  password            = random_password.read_user_password.result
}

resource "azuread_directory_role_assignment" "global_reader_assigment" {
  role_id = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
  principal_object_id = azuread_user.read_user.object_id
}

resource "azurerm_role_assignment" "subscription_reader_access" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azuread_user.read_user.object_id
}

/*---------------------------------------------*/


#################################################
// Create publicly accessible blob container
#################################################

resource "random_id" "challenge_instance_id" {
  byte_length = 4
}

locals {
  uploaded_files = fileset("${path.module}/data/container", "*")
}

resource "azurerm_storage_account" "sa" {
  name                      = "cloudjumping${random_id.challenge_instance_id.hex}"
  resource_group_name       = azurerm_resource_group.cloudjumping.name
  location                  = azurerm_resource_group.cloudjumping.location
  account_tier              = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules = [
      local.user_ip
    ]
  }
}

resource "azurerm_storage_container" "container" {
  name                       = "files"
  storage_account_id       = azurerm_storage_account.sa.id
  container_access_type      = "container"
}

resource "azurerm_storage_blob" "blob" {
  for_each               = { for file in local.uploaded_files : file => file }
  name                   = each.value
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = "${path.module}/data/container/${each.value}"
}

# give player permissions to read storage account and data
resource "azurerm_role_assignment" "storage_blob_reader" {
  principal_id          = var.player_object_id
  role_definition_name  = "Storage Blob Data Reader"
  scope                 = azurerm_storage_account.sa.id
}

resource "azurerm_role_assignment" "reader" {
  principal_id         = var.player_object_id
  role_definition_name = "Reader"
  scope                = azurerm_storage_account.sa.id
}

/*---------------------------------------------*/


#################################################
// Create a managed identity
#################################################

resource "azurerm_user_assigned_identity" "contributor_managed_identity" {
  name                = "contributor-managed-identity"
  resource_group_name       = azurerm_resource_group.cloudjumping.name
  location                  = azurerm_resource_group.cloudjumping.location
}

# managed identity should have contributor role for cloudjumping resource group
resource "azurerm_role_assignment" "contributor" {
  scope                = azurerm_resource_group.cloudjumping.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.contributor_managed_identity.principal_id
}

/*---------------------------------------------*/


#################################################
// Create Linux VM with a managed identity
#################################################

# vm1 (jump-host) gets deployed from a template
data "local_file" "jump_host_template" {
  filename = "${path.module}/data/jump-host-template.json"
}

resource "random_password" "jump_host_user_password" {
  length  = 16
  special = true
}

resource "azurerm_resource_group_template_deployment" "jump_host_vm" {
  name                = "jump_host"
  resource_group_name = azurerm_resource_group.cloudjumping.name
  deployment_mode     = "Incremental"
  template_content    = data.local_file.jump_host_template.content
  parameters_content  = jsonencode({
    adminPasswordOrKey = {
      value = random_password.jump_host_user_password.result
    }
  })

  depends_on = [
    azurerm_role_assignment.contributor
  ]
}

/*---------------------------------------------*/


#################################################
// Create Linux VM with the flag
#################################################

resource "random_password" "linux_vm_user_password" {
  length  = 16
  special = true
}

resource "azurerm_virtual_network" "linux_vm_vnet" {
  name                = "production-vnet"
  address_space       = ["10.2.0.0/16"]
  resource_group_name       = azurerm_resource_group.cloudjumping.name
  location                  = azurerm_resource_group.cloudjumping.location
}

resource "azurerm_subnet" "linux_vm_subnet" {
  name                 = "production-subnet"
  resource_group_name       = azurerm_resource_group.cloudjumping.name
  virtual_network_name = azurerm_virtual_network.linux_vm_vnet.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_public_ip" "linux_vm_ip" {
  name                = "production-public-ip"
  resource_group_name = azurerm_resource_group.cloudjumping.name
  location            = azurerm_resource_group.cloudjumping.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "linux_vm_nic" {
  name                = "production-vm-nic"
  resource_group_name = azurerm_resource_group.cloudjumping.name
  location            = azurerm_resource_group.cloudjumping.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.linux_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux_vm_ip.id
  }

  depends_on = [
    azurerm_public_ip.linux_vm_ip
  ]
}

resource "azurerm_network_security_group" "ctf_nsg" {
  name                = "ctf-nsg"
  resource_group_name = azurerm_resource_group.cloudjumping.name
  location            = azurerm_resource_group.cloudjumping.location

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
  subnet_id                 = azurerm_subnet.linux_vm_subnet.id
  network_security_group_id = azurerm_network_security_group.ctf_nsg.id
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                            = "production-server"
  resource_group_name             = azurerm_resource_group.cloudjumping.name
  location                        = azurerm_resource_group.cloudjumping.location
  size                            = "Standard_B1s"
  admin_username                  = "azureadmin"
  admin_password                  = random_password.linux_vm_user_password.result
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.linux_vm_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "production-server-disk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  connection {
    type     = "ssh"
    host     = azurerm_public_ip.linux_vm_ip.ip_address
    user     = "azureadmin"
    password = random_password.linux_vm_user_password.result
  }

  provisioner "file" {
    source      = "${path.module}/data/flag.txt"
    destination = "/home/azureadmin/flag.txt"
  }

  depends_on = [
    azurerm_public_ip.linux_vm_ip,
    azurerm_network_interface.linux_vm_nic
  ]
}