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

# provider "aws" {
#   alias   = "us-east-2"
#   region  = "us-east-2"
#   profile = var.aws_local_profile
# }

# provider "aws" {
#   alias   = "us-west-1"
#   region  = "us-west-1"
#   profile = var.aws_local_profile
# }

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
  AWS_REGION = var.AWS_REGION
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3

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
  AWS_REGION = var.AWS_REGION
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3

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
  AWS_REGION = var.AWS_REGION
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3
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
  AWS_REGION = var.AWS_REGION
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3
}

module "challenge_the_topic_is_execution" {
  source = "./challenges/the-topic-is-execution"
  count = var.the_topic_is_execution_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn) 
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
  ctf_starting_user_name = module.enabled.ctf_starting_user_name
  AWS_REGION = var.AWS_REGION
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3
}

module "challenge_root" {
  source = "./challenges/root"
  count = var.root_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn) 
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  aws_root_user = format("arn:aws:iam::%s:root", data.aws_caller_identity.current.account_id)
  user_ip = local.user_ip
  ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
  ctf_starting_user_name = module.enabled.ctf_starting_user_name
  AWS_REGION = var.AWS_REGION
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3
}

module "challenge_double_tap" {
    source = "./challenges/double_tap"
    count = var.double_tap_enabled ? 1 : 0
    aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn) 
    account_id = data.aws_caller_identity.current.account_id
    aws_local_profile = var.aws_local_profile
    user_ip = local.user_ip
    ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
    ctf_starting_user_name = module.enabled.ctf_starting_user_name
    AWS_REGION = var.AWS_REGION
    AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
    AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
    AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3
  }

module "challenge_needles" {
    source = "./challenges/needles"
    count = var.needles_enabled ? 1 : 0
    aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn) 
    account_id = data.aws_caller_identity.current.account_id
    aws_local_profile = var.aws_local_profile
    user_ip = local.user_ip
    ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
    ctf_starting_user_name = module.enabled.ctf_starting_user_name
    AWS_REGION = var.AWS_REGION
    AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
    AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
    AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3
  }

  module "challenge_pain" {
    source = "./challenges/pain"
    count = var.pain_enabled ? 1 : 0
    aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn) 
    account_id = data.aws_caller_identity.current.account_id
    aws_local_profile = var.aws_local_profile
    user_ip = local.user_ip
    ctf_starting_user_arn = module.enabled.ctf_starting_user_arn
    ctf_starting_user_name = module.enabled.ctf_starting_user_name
    AWS_REGION = var.AWS_REGION
    AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
    AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
    AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3
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
  AWS_REGION = var.AWS_REGION
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3

}

module "challenge_furls1" {
  source = "./challenges/furls1"
  count = var.furls1_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  AWS_REGION = var.AWS_REGION
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3
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
  AWS_REGION = var.AWS_REGION
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3
}

module "challenge_the_topic_is_exposure" {
  source = "./challenges/the-topic-is-exposure"
  count = var.the_topic_is_exposure_enabled ? 1 : 0
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn) 
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  AWS_REGION = var.AWS_REGION
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3

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
  AWS_REGION = var.AWS_REGION
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3

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
    AWS_REGION = var.AWS_REGION
    AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
    AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
    AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3
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
  AWS_REGION = var.AWS_REGION    
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3

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
  AWS_REGION = var.AWS_REGION    
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3

}

##############################################
#  Category -- Exploit Trusted Relationship  #
##############################################


module "challenge_trust_me" {  
  source = "./challenges/trust-me"
  count = (var.trust_me_enabled && var.github_repo != "") ? 1 : 0    
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  account_id = data.aws_caller_identity.current.account_id
  aws_local_profile = var.aws_local_profile
  user_ip = local.user_ip
  github_repo = var.github_repo
  AWS_REGION = var.AWS_REGION    
  AWS_REGION_SUB_1 = var.AWS_REGION_SUB_1
  AWS_REGION_SUB_2 = var.AWS_REGION_SUB_2
  AWS_REGION_SUB_3 = var.AWS_REGION_SUB_3

}

locals {
  enabled_challenges = [
    var.its_a_secret_enabled ?            "its_a_secret                 | No Cost      |" : "",
    var.its_another_secret_enabled ?      "its_another_secret           | No Cost      |" : "",
    var.backwards_enabled ?               "backwards                    | No cost      |" : "",
    var.trust_me_enabled ?                "trust_me                     | No cost      |" : "",
    var.furls1_enabled ?                  "furls1                       | No cost      |" : "",
    var.furls2_enabled ?                  "furls2                       | No cost      |" : "",
    var.the_topic_is_exposure_enabled ?   "the_topic_is_exposure        | No cost      |" : "",
    var.the_topic_is_execution_enabled ?  "the_topic_is_execution       | No cost      |" : "",
    var.middle_enabled ?                  "middle                       | No cost      |" : "",
    var.needles_enabled ?                 "needles                      | No Cost      |" : "",
    var.pain_enabled ?                    "pain                         | No Cost      |" : "",    
    var.bastion_enabled ?                 "bastion                      | $4/month     |" : "",
    var.wyatt_enabled ?                   "wyatt                        | $4/month     |" : "",
    var.double_tap_enabled ?              "double_tap                   | $9/month     |" : "",
    var.variable_enabled ?                "variable                     | $13/month    |" : "",
    var.search1and2_enabled ?             "search1and2                  | $27/month    |" : ""
  ]
}

output "CTF_Start_User_Access_Key_Id" {
  value     = module.enabled.ctf_user_output_access_key_id

}
output "CTF_Start_User_Secret_Access_Key" {
  value     = module.enabled.ctf_user_output_secret_access_key
  sensitive = true
}

output "Next_Steps" {
  value = <<-EOT
+---------
| 
|   +-------------------------------------------------------------------------------------+
|   | Deployment Information:                                                             |
|   |                                                                                     |
|   | Profile Used:             ${var.aws_local_profile}
|   | Deployment User:          ${data.aws_caller_identity.current.arn}             
|   | CloudFoxable deployed to: ${data.aws_caller_identity.current.account_id}                                              |
|   | Scoreboard URL:           https://cloudfoxable.bishopfox.com                        |
|   | CTF Starting User:        ${module.enabled.ctf_starting_user_arn}          |
|   +-------------------------------------------------------------------------------------+
| 
| Next steps:
| 
|   1. Set up your starting user credentials (From within this directory):
|  
|      +---------------------------------+  
|      | Option 1: Configure new profile |
|      +---------------------------------+  
|      Note: This command below needs to be executed from this directory.
|      echo "" >> ~/.aws/credentials && echo "[cloudfoxable]" >> ~/.aws/credentials && echo "aws_access_key_id = `terraform output -raw CTF_Start_User_Access_Key_Id`" >> ~/.aws/credentials && echo "aws_secret_access_key = `terraform output -raw CTF_Start_User_Secret_Access_Key`" >> ~/.aws/credentials && echo "region = ${var.AWS_REGION}" >> ~/.aws/credentials
|
|      +---------------------------------+  
|      | Option 2: Environment variables |
|      +---------------------------------+
|      AWS_ACCESS_KEY_ID=`terraform output CTF_Start_User_Access_Key_Id`
|      AWS_SECRET_ACCESS_KEY=`terraform output CTF_Start_User_Secret_Access_Key`
|      AWS_REGION=${var.AWS_REGION}
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
|
| Note: The cost/month does not account for AWS Free Tier discounts. If you have not 
| already used your credits for the month, your costs will be lower.
+---------
EOT
}

