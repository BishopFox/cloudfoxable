terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.50"
    }
    
    http = {
      source  = "hashicorp/http"
      version = "~> 2.1.0"
    }   
  }
}

provider "aws" {
  region                  = var.AWS_REGION   
  profile                 = var.aws_local_profile
}


data "aws_caller_identity" "current" {}


data "http" "current_ip" {
  url = "https://ifconfig.me"
}

locals {
  user_ip = var.user_ip != "" ? chomp(var.user_ip) : chomp(data.http.current_ip.body)

}



module "enabled" {
  source = "./modules/enabled"
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
}


###########################################
#  Category -- Assumed Breach: Principal  #
###########################################

module "challenge_its_a_secret" {
  source = "./challenges/its-a-secret"
  count = var.challenge_its_a_secret_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
  ctf_starting_user_name = module.enabled.ctf_starting_user_name

}



###################################################
#  Category -- Exploit Public-Facing Application  #
###################################################

module "challenge_opensearch_github_pat" {
  source = "./challenges/opensearch-github-pat"
  count = var.challenge_opensearch_github_pat_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
}

# module "challenge_lambda_functionurl" {
#   source = "./challenges/lambda-functionurl"
#   count = var.challenge_lambda_functionurl_enabled ? 1 : 0
#   aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
#   account_id = data.aws_caller_identity.current.account_id
#   aws_local_profile = var.aws_local_profile
#   user_ip = local.user_ip
# }


##############################################
#  Category -- Exploit Trusted Relationship  #
##############################################


module "challenge_oidc_github" {  
  source = "./challenges/oidc-github"
  count = var.challenge_oidc_github_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  github_repo = var.github_repo
}









# module "challenge_opensearch_dynamodb" {
#   source = "./challenges/opensearch-dynamodb"
#   count = var.challenge_opensearch_dynamodb_enabled ? 1 : 0
#   aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
#   account_id = data.aws_caller_identity.current.account_id
#   aws_local_profile = var.aws_local_profile
#   user_ip = local.user_ip
# }


# module "challenge_github_pat" {
#   source = "./challenges/github-pat"
#   count = var.challenge_github_pat_enabled ? 1 : 0
#   aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
#   account_id = data.aws_caller_identity.current.account_id
#   aws_local_profile = var.aws_local_profile
#   user_ip = local.user_ip
#   ctf_starting_user_arn = module.enabled.ctf_starting_user_arn

# }







# output "AWS_Profiled_Used" {
#   value = var.aws_local_profile
# }


# output "CTF_Deployed_to_Account" {
#   value = data.aws_caller_identity.current.account_id
# }

# output "CTF_Deployment_Caller_Arn" {
#   value = data.aws_caller_identity.current.arn
# }

# # output "caller_id" {
# #   value = data.aws_caller_identity.current.user_id
# # }

# output "CTF_Start_User_Access_Key_Id" {
#   value     = module.enabled.ctf_user_output_access_key_id
  
# }
# output "CTF_Start_User_Secret_Access_Key" {
#   value     = module.enabled.ctf_user_output_secret_access_key
#   sensitive = true
# }

# output "Participant_User_IP_For_Security_groups" {
#   value = local.user_ip
# }

# output "CTF_Start_User_Arn" {
#   value       = module.enabled.ctf_starting_user_arn
#   description = "ARN of the CTF starting user"
# }

# output "Scoreboard_URL" {
#   value       = "https://cloudfoxable.bishopfox.com"
#   description = "URL of the CTF scoreboard"
# }


output "ZZ_First_Flag" {
  value       = "FLAG{congrats_you_are_now_a_terraform_expert_happy_hunting}"
  description = "First flag of the CTF"
}

output "Next_Steps" {
  value = <<-EOT
+---------
| 
|   +----------------------------------------------------------------------------+
|   | Deployment Information:                                                    |
|   |                                                                            |
|   | Profile Used:             ${var.aws_local_profile}
|   | Deployment User:          ${data.aws_caller_identity.current.arn}    |
|   | CloudFoxable deployed to: ${data.aws_caller_identity.current.account_id}                                     |
|   | Scoreboard URL:           https://cloudfoxable.bishopfox.com               |
|   | CTF Starting User:        ${module.enabled.ctf_starting_user_arn} |
|   +----------------------------------------------------------------------------+
| 
| Next steps:
| 
|   1. Set up your starting user credentials (From within this directory):
|  
|      +---------------------------------+  
|      | Option 1: Environment variables |
|      +---------------------------------+
|      AWS_ACCESS_KEY_ID=`terraform output CTF_Start_User_Access_Key_Id`
|      AWS_SECRET_ACCESS_KEY=`terraform output CTF_Start_User_Secret_Access_Key`
|      AWS_REGION=${var.AWS_REGION}
|
|      +---------------------------------+  
|      | Option 2: Configure new profile |
|      +---------------------------------+  
|      echo "[cloudfoxable]" >> ~/.aws/credentials
|      echo "aws_access_key_id = `terraform output -raw CTF_Start_User_Access_Key_Id`" >> ~/.aws/credentials
|      echo "aws_secret_access_key = `terraform output -raw CTF_Start_User_Secret_Access_Key`" >> ~/.aws/credentials
|      echo "region = ${var.AWS_REGION}" >> ~/.aws/credentials
|
|   2. Verify your credentials are working:
|
|      aws sts get-caller-identity --profile cloudfoxable
|
|   3. Head back to https://cloudfoxable.bishopfox.com and complete the first challenge!
|
|      You'll need this: FLAG{congrats_you_are_now_a_terraform_expert_happy_hunting}
|
+---------
EOT
}

