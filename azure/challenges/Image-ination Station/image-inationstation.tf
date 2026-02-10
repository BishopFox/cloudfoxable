# resource group
resource "azurerm_resource_group" "imageinationstation" {
  name      = "imageinationstationRG"
  location  = var.azure_region
}

resource "random_id" "suffix" {
  byte_length = 4
}

# create container registry
resource "azurerm_container_registry" "acr" {
  name                = "myacr${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.imageinationstation.name
  location            = azurerm_resource_group.imageinationstation.location
  sku                 = "Basic"
  admin_enabled       = true
}

# push image from data folder to container registry
resource "null_resource" "docker_push" {
  provisioner "local-exec" {
    command = <<EOT
      cd "challenges/Image-ination Station/data"
      docker build -t ${azurerm_container_registry.acr.login_server}/my-app:latest .
      docker login ${azurerm_container_registry.acr.login_server} -u ${azurerm_container_registry.acr.admin_username} -p ${azurerm_container_registry.acr.admin_password}
      docker push ${azurerm_container_registry.acr.login_server}/my-app:latest
    EOT
    interpreter = ["/bin/sh", "-c"]
  }

  depends_on = [azurerm_container_registry.acr]
  triggers = {
    output = var.depends_on_output
  }
}

# provide ctf player with pull permissions
resource "azurerm_role_assignment" "acr_pull_access" {
  principal_id         = var.player_object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

# provide ctf player with permissions to read container registry
resource "azurerm_role_assignment" "acr_read_access" {
  principal_id         = var.player_object_id
  role_definition_name = "Reader"
  scope                = azurerm_container_registry.acr.id
}