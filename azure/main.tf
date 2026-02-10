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
  source                      = "./challenges/Not so secret"
  azure_region                = var.azure_region
  player_upn                  = azuread_user.ctf_user.user_principal_name 
  player_object_id            = azuread_user.ctf_user.object_id
}

module "challenge_permisery" {
  source                      = "./challenges/Permisery"
  azure_region                = var.azure_region
  player_upn                  = azuread_user.ctf_user.user_principal_name 
  player_object_id            = azuread_user.ctf_user.object_id
}

module "challenge_image-inationcontinuation" {
  source                      = "./challenges/Image-ination Continuation"
  azure_region                = var.azure_region
  player_upn                  = azuread_user.ctf_user.user_principal_name 
  player_object_id            = azuread_user.ctf_user.object_id
}

module "challenge_image-inationstation" {
  source                      = "./challenges/Image-ination Station"
  azure_region                = var.azure_region
  player_upn                  = azuread_user.ctf_user.user_principal_name 
  player_object_id            = azuread_user.ctf_user.object_id
  depends_on                  = [module.challenge_image-inationcontinuation]
  depends_on_output = module.challenge_image-inationcontinuation.some_output #needed to make sure stuff finishes before other stuff
}

module "challenge_vmiam" {
  source                      = "./challenges/VM I Am"
  azure_region                = var.azure_region
  player_upn                  = azuread_user.ctf_user.user_principal_name 
  player_object_id            = azuread_user.ctf_user.object_id
}

module "challenge_cloudjumping" {
  source                      = "./challenges/Cloud Jumping"
  azure_region                      = var.azure_region
  player_upn                  = azuread_user.ctf_user.user_principal_name 
  player_object_id            = azuread_user.ctf_user.object_id
}

output "Next_Steps" {
  value = <<-EOT
  +---------
  | 
  |   +-------------------------------------------------------------------------------------+
  |   | Deployment Information:                                                             |
  |   |                                                                                     |
  |   | Profile Used:             TBD                                                       |
  |   | Deployment User:          TBD                                                       |
  |   | CloudFoxable deployed to: TBD                                                       |
  |   | Scoreboard URL:           https://cloudfoxable.bishopfox.com                        |
  |   | CTF Starting User:        TBD                                                       |
  |   +-------------------------------------------------------------------------------------+
  | 
  | Next steps:
  | 
  |   1. Set up your starting user credentials (From within this directory):
  |  
  |      TBD
  |
  |   2. Verify your credentials are working:
  |
  |      TBD
  |
  |   3. Head back to https://cloudfoxable.bishopfox.com and complete the first challenge!
  |
  |      You'll need this: FLAG{congrats_you_set_up_Terraform_with_Azure}
  |
  |  +---------------------------------+--------------+
  |  |  Currently Enabled Challenges   |  Cost/Month  | 
  |  +---------------------------------+--------------+
  |  |    TBD
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

output "credentials" {
  value     = local.credentials_text
  sensitive = true
}

resource "local_file" "credentials" {
  filename        = "credentials.txt"
  content         = local.credentials_text
  file_permission = "0600"
}