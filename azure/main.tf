# Configure the Azure provider

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.26.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  required_version = ">= 1.3"
}

provider "azurerm" {
  features {
    key_vault {
      recover_soft_deleted_key_vaults = false
      purge_soft_delete_on_destroy    = true
    }
  }
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}

# user password
resource "random_password" "ctf_user_pw" {
  length           = 14 
  special          = true
  override_special = "!@#$%^&*-_=+"
}

# user account, which will be "willem@<azure-domain>
resource "azuread_user" "ctf_user" {
  display_name                = "willem"
  user_principal_name         = "willem${var.domain}"
  mail_nickname               = "willem"
  password                    = random_password.ctf_user_pw.result
  account_enabled             = true
}

module "challenge_notsosecret" {
  count                       = var.notsosecret_enabled ? 1 : 0
  source                      = "./challenges/Not so secret"
  azure_region                = var.azure_region
  player_upn                  = azuread_user.ctf_user.user_principal_name 
  player_object_id            = azuread_user.ctf_user.object_id
}

module "challenge_permisery" {
  count                       = var.permisery_enabled ? 1 : 0
  source                      = "./challenges/Permisery"
  azure_region                = var.azure_region
  player_upn                  = azuread_user.ctf_user.user_principal_name 
  player_object_id            = azuread_user.ctf_user.object_id
}

module "challenge_image-inationcontinuation" {
  count                       = var.imageination_enabled ? 1 : 0
  source                      = "./challenges/Image-ination Continuation"
  azure_region                = var.azure_region
  player_upn                  = azuread_user.ctf_user.user_principal_name 
  player_object_id            = azuread_user.ctf_user.object_id
}

module "challenge_image-inationstation" {
  count                       = var.imageination_enabled ? 1 : 0
  source                      = "./challenges/Image-ination Station"
  azure_region                = var.azure_region
  player_upn                  = azuread_user.ctf_user.user_principal_name 
  player_object_id            = azuread_user.ctf_user.object_id
  depends_on                  = [module.challenge_image-inationcontinuation]
  depends_on_output           = module.challenge_image-inationcontinuation[0].some_output # needed to make sure stuff finishes before other stuff
}

module "challenge_vmiam" {
  count                       = var.vmiam_enabled ? 1 : 0
  source                      = "./challenges/VM I Am"
  azure_region                = var.azure_region
  player_upn                  = azuread_user.ctf_user.user_principal_name 
  player_object_id            = azuread_user.ctf_user.object_id
}

module "challenge_cloudjumping" {
  count                       = var.cloudjumping_enabled ? 1 : 0
  source                      = "./challenges/Cloud Jumping"
  azure_region                      = var.azure_region
  player_upn                  = azuread_user.ctf_user.user_principal_name 
  player_object_id            = azuread_user.ctf_user.object_id
}

locals {
  enabled_challenges = compact([
    var.notsosecret_enabled                ? "Not So Secret (~$0.01/month)" : "",
    var.permisery_enabled                  ? "Permisery (~$0/month)" : "",
    var.imageination_enabled               ? "Image-ination Challenges (~$5/month)" : "",
    var.vmiam_enabled                      ? "VM I Am (~$15/month)" : "",
    var.cloudjumping_enabled               ? "Cloud Jumping (~$15/month)" : ""
  ])
}

output "Next_Steps" {
  value = <<EOT
  +---------
  | 
  |   +---------------------------------------------------------------------------------------------+
  |   | Deployment Information:                                                                     |
  |   |                                                                                             |
  |   | CloudFoxable deployed to: Subscription ${data.azurerm_client_config.current.subscription_id}|
  |   |                           Tenant ${data.azurerm_client_config.current.tenant_id}            |
  |   | Scoreboard URL:           https://cloudfoxable.bishopfox.com                                |
  |   | CTF Starting User:        Willem                                                            |
  |   | Credentials:              cat credentials.txt                                               |
  |   +---------------------------------------------------------------------------------------------+
  | 
  | Next steps:
  | 
  |   1. Access the credentials for your CTF user:
  |  
  |      cat credentials.txt
  |
  |   2. Logout your admin user:
  |
  |      az logout 
  |
  |   3. Verify your CTF user's credentials are working:
  |
  |      az login
  |
  |   3. Head back to https://cloudfoxable.bishopfox.com and complete the first challenge!
  |
  |      You'll need this: FLAG{congrats_you_set_up_Terraform_with_Azure}
  |
  |  +---------------------------------+--------------+
  |  |  Currently Enabled Challenges   |  Cost/Month  | 
  |  +---------------------------------+--------------+
  |  |  ${length(local.enabled_challenges) > 0 ? join("\n|  |    ", local.enabled_challenges) : "None"}
  |  +------------------------------------------------+
  |
  +---------
  EOT
}

locals {
  credentials_text = <<-EOT
  client_id = ${azuread_user.ctf_user.user_principal_name}
  password = ${random_password.ctf_user_pw.result}
  EOT
}

resource "local_file" "credentials" {
  filename        = "credentials.txt"
  content         = local.credentials_text
  file_permission = "0600"
}