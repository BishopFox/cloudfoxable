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
  count = var.its_a_secret_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
  ctf_starting_user_name = module.enabled.ctf_starting_user_name

}

module "challenge_its_another_secret" {
  source = "./challenges/its-another-secret"
  count = var.its_another_secret_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
  ctf_starting_user_name = module.enabled.ctf_starting_user_name
}

module "challenge_backwards" {
  source = "./challenges/backwards"
  count = var.backwards_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
  ctf_starting_user_name = module.enabled.ctf_starting_user_name
}

module "challenge_the_topic_is_execution" {
  source = "./challenges/the-topic-is-execution"
  count = var.the_topic_is_execution_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn) 
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
}


###################################################
#  Category -- Exploit Public-Facing Application  #
###################################################

module "challenge_search1and2" {
  source = "./challenges/search1and2"
  count = var.search1and2_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
  ctf_starting_user_name = module.enabled.ctf_starting_user_name

}

module "challenge_furls1" {
  source = "./challenges/furls1"
  count = var.furls1_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
}


module "challenge_furls2" {
  source = "./challenges/furls2"
  count = var.furls2_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
  ctf_starting_user_name = module.enabled.ctf_starting_user_name
}

module "challenge_the_topic_is_exposure" {
  source = "./challenges/the-topic-is-exposure"
  count = var.the_topic_is_exposure_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn) 
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip

}

module "challenge_middle" {
  source = "./challenges/middle"
  count = var.middle_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn) 
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
  ctf_starting_user_name = module.enabled.ctf_starting_user_name

}

  module "challenge_wyatt" {
    source = "./challenges/wyatt"
    count = var.wyatt_enabled ? 1 : 0
    aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn) 
    account_id = data.aws_caller_identity.current.account_id
    aws_local_profile = var.aws_local_profile
    user_ip = local.user_ip
    vpc_id = module.enabled.vpc_id
    vpc_cidr = module.enabled.vpc_cidr
    subnet1_id = module.enabled.subnet1_id
    subnet2_id = module.enabled.subnet2_id
    subnet3_id = module.enabled.subnet3_id
    }



########################################################################
#  Category -- Assumed Breach: Accplication Compromise/Network Access  #
########################################################################

module "challenge_bastion" {
  source = "./challenges/bastion"
  count = var.bastion_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
  ctf_starting_user_name = module.enabled.ctf_starting_user_name
  vpc_id = module.enabled.vpc_id
  subnet1_id = module.enabled.subnet1_id
  subnet2_id = module.enabled.subnet2_id
  subnet3_id = module.enabled.subnet3_id

}

module "challenge_variable" {
  source = "./challenges/variable"
  count = var.variable_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  intra-sg-access-id = module.challenge_bastion[0].intra-sg-access-id
  subnet1_id = module.enabled.subnet1_id
  subnet2_id = module.enabled.subnet2_id
  subnet3_id = module.enabled.subnet3_id
}

##############################################
#  Category -- Exploit Trusted Relationship  #
##############################################


module "challenge_blurred_lines-1" {  
  source = "./challenges/blurred_lines_1"
  count = (var.blurred_lines-1_enabled && var.github_repo != "") ? 1 : 0    
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  github_repo = var.github_repo
}

# locals {
#   error_message = "You have tried to enable the challenge by setting var.blurred_lines-1_enabled to true, but you forgot to specify a repo in var.github_repo."
# }

# resource "null_resource" "validate_variables" {
#   count = var.blurred_lines-1_enabled && var.github_repo == "" ? 1 : 0

#   provisioner "local-exec" {
#     command = "echo '${local.error_message}'; exit 1"
#   }
# }








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




locals {
  enabled_challenges = [
    var.secretsmanager_enabled ?          "secretsmanager" : "",
    var.its_a_secret_enabled ?            "its_a_secret                 | $.40/month   |" : "",
    var.its_another_secret_enabled ?      "its_another_secret           | $.40/month   |" : "",
    var.backwards_enabled ?               "backwards                    | No cost      |" : "",
    var.blurred_lines-1_enabled ?         "blurred_lines-1              | No cost      |" : "",
    var.furls1_enabled ?                  "furls1                       | No cost      |" : "",
    var.furls2_enabled ?                  "furls2                       | No cost      |" : "",
    var.the_topic_is_exposure_enabled ?   "the_topic_is_exposure        | No cost      |" : "",
    var.the_topic_is_execution_enabled ?  "the_topic_is_execution       | No cost      |" : "",
    var.middle_enabled ?                  "middle                       | No cost      |" : "",
    var.search1and2_enabled ?             "search1and2                  | $27/month    |" : "",
    #var.opensearch_dynamodb_enabled ? "opensearch_dynamodb" : "",
    var.github_pat_enabled ?              "github_pat" : "",
    var.bastion_enabled ?                 "bastion                      | $4/month     |" : "",
    var.variable_enabled ?                "variable                     | $13/month    |" : "",
    var.wyatt_enabled ?                   "wyatt                        | $4/month     |" : ""

  ]
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
|   1. Set up your starting user credentials (From within this directory):sum
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
|  +---------------------------------+--------------+
|  |  Currently Enabled Challenges   |  Cost/Month  | 
|  +---------------------------------+--------------+
|  |    ${join("\n|  |    ", [for c in local.enabled_challenges : c if c != ""])}
|  +------------------------------------------------+
+---------
EOT
}

