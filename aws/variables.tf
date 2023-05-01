variable "aws_local_profile" {
  description = "What local profile should terraform use to interact with your AWS account(s)"
  type        = string
  default     = "default"
}

variable "aws_local_creds_file" {
  description = "Location of your local credentials file"
  type        = string
  default     = "~/.aws/credentials"
}

variable "aws_assume_role_arn" {
  description = "This is the arn of an already existing principal that can assume into any roles that are created"
  type        = string
  default     = ""
}

variable "shared_high_priv_servicerole" {
  description = "This is the arn of high priv service role that is attached to lambda's ec2's, etc. to facilitate privesc"
  type        = string
  default     = ""
}

variable "AWS_REGION" {
  type    = string
  default = "us-west-2" 
}

variable "AWS_REGION_SUB_1" {
  type    = string
  default = "us-west-2a"
}

variable "AWS_REGION_SUB_2" {
  type    = string
  default = "us-west-2b"
}

variable "AWS_REGION_SUB_3" {
  type    = string
  default = "us-west-2c"
}

variable "user_ip" {
  description = "The current user's IP address"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "The github repo for the OIDC-GitHub challenge"
  type        = string
  default     = null
}

variable "challenge_oidc_github_enabled" {
  description = "Enable or disable oidc_github challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "challenge_opensearch_dynamodb_enabled" {
  description = "Enable or disable the open search dynamodb challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "challenge_lambda_functionurl_enabled" {
  description = "Enable or disable lambda_functionurl challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

# variable "challenge_secretsmanager_enabled" {
#   description = "Enable or disable secretsmanager challenge (true = enabled, false = disabled)"
#   type        = bool
#   default     = false
# }

variable "challenge_github_pat_enabled" {
  description = "Enable or disable github_pat challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "challenge_opensearch_github_pat_enabled" {
  description = "Enable or disable opensearch_github_pat challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "challenge_its_a_secret_enabled" {
  description = "Enable or disable its_a_secret challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}