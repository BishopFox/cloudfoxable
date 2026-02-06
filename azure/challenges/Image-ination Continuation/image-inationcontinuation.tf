resource "random_id" "suffix" {
  byte_length = 4
}

resource "random_password" "sp_pwd" {
  length  = 20
  special = true
}

data "azurerm_client_config" "current" {}

# create a key vault
resource "azurerm_key_vault" "ctf" {
  name                        = "ctfkv${random_id.suffix.hex}"
  location                    = var.resource_group_location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7
  enable_rbac_authorization   = true
}

# place the flag in the key vault
resource "azurerm_key_vault_secret" "flag" {
  name         = "flag"
  value        = "Flag{protect_those_service_principal_creds}"
  key_vault_id = azurerm_key_vault.ctf.id
}

# create an identity for the logic app
resource "azurerm_user_assigned_identity" "logicapp_identity" {
  name                = "logicapp-mi-${random_id.suffix.hex}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}

locals {
  logicapp_name = "flag-logicapp-${random_id.suffix.hex}"
}

# create a deployment template for the logic app
resource "azurerm_resource_group_template_deployment" "logicapp_with_flag" {
  name                = "logicapp-deploy-${random_id.suffix.hex}"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema" = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion" = "1.0.0.0",
    "parameters" = {},
    "resources" = [
      {
        "type" = "Microsoft.Logic/workflows",
        "apiVersion" = "2019-05-01",
        "name" = "${local.logicapp_name}",
        "location" = var.resource_group_location,
        "identity" = {
          "type" = "SystemAssigned"
        },
        "properties" = {
          "definition" = {
            "$schema" = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
            "actions" = {
              "GetFlag" = {
                "type" = "Http",
                "inputs" = {
                  "method" = "GET",
                  "uri" = "${azurerm_key_vault_secret.flag.id}?api-version=7.2",
                  "authentication" = {
                    "type" = "ManagedServiceIdentity",
                    "audience": "https://vault.azure.net"
                  }
                },
                "runAfter" = {}
              },
              "Response" = {
                "type" = "Response",
                "inputs" = {
                  "body" = {
                    "flag" = "@body('GetFlag').value"
                  },
                  "statusCode" = 200
                },
                "runAfter" = {
                  "GetFlag" = ["Succeeded"]
                }
              }
            },
            "triggers" = {
              "manual" = {
                "type" = "Request",
                "kind" = "Http",
                "inputs" = {
                  "schema" = {}
                }
              }
            },
            "outputs" = {}
          },
          "state" = "Enabled"
        }
      }
    ]
  })
}

# provide admin permissions to the key vault for the terraform deployment user, which should be azure admin
resource "azurerm_role_assignment" "kv_admin" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.ctf.id
}

# get the logic app identity and store in a local file
resource "null_resource" "get_logicapp_identity" {
  provisioner "local-exec" {
    command = <<EOT
    cd "challenges/Image-ination Continuation/data/"
      az logic workflow show \
        --name ${local.logicapp_name} \
        --resource-group ${var.resource_group_name} \
        --query "identity.principalId" \
        --output tsv > logicapp_identity.txt
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  triggers = {
    always_run = timestamp()
  }

  depends_on = [azurerm_resource_group_template_deployment.logicapp_with_flag]
}

data "local_file" "logicapp_identity" {
  filename = "challenges/Image-ination Continuation/data/logicapp_identity.txt"
  depends_on = [null_resource.get_logicapp_identity]
}

# provide logic app with permissions to get the flag
resource "azurerm_role_assignment" "logicapp_kv_reader" {
  principal_id         = data.local_file.logicapp_identity.content
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.ctf.id

  depends_on = [data.local_file.logicapp_identity]
}

# create the logic app
resource "azuread_application" "sp_app" {
  display_name = "ctf-logicapp-access"
}

# create service principal
resource "azuread_service_principal" "sp" {
  client_id = azuread_application.sp_app.client_id
}

# create service principal password
resource "azuread_service_principal_password" "sp_secret" {
  service_principal_id = azuread_service_principal.sp.id
  end_date             = timeadd(timestamp(), "720h")   

  lifecycle {
    create_before_destroy = true
  }
}

# give service principal Reader permissions in the environment
resource "azurerm_role_assignment" "sp_reader" {
  principal_id         = azuread_service_principal.sp.object_id
  role_definition_name = "Reader"
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
}

# Give service principal logic app contributor permissions
resource "azurerm_role_assignment" "logicapp_reader" {
  principal_id         = azuread_service_principal.sp.object_id
  role_definition_name = "Logic App Contributor"
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Logic/workflows/flag-logicapp-${random_id.suffix.hex}"

  depends_on = [azurerm_resource_group_template_deployment.logicapp_with_flag]
}

# generate local file with service principal credentials, which get stored in the container image from the image-ination station challenge
resource "null_resource" "generate_sp_creds" {
  triggers = {
    password_version = azuread_service_principal_password.sp_secret.key_id
  }

  provisioner "local-exec" {
    command = <<EOT
echo '{
  "client_id": "${azuread_application.sp_app.client_id}",
  "client_secret": "${azuread_service_principal_password.sp_secret.value}",
  "tenant_id": "${data.azurerm_client_config.current.tenant_id}",
  "subscription_id": "${data.azurerm_client_config.current.subscription_id}",
  "resource": "https://management.azure.com/",
  "resource_group": "${var.resource_group_name}"
}' > challenges/Image-ination\ Station/data/sp-creds.json
EOT
  }
}