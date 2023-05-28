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

variable "intra-sg-access-id" {
  description = "The ID of the intra-sg-access security group"
  type        = string
  default     = null
}
variable "github_repo" {
  description = "The github repo for the OIDC-GitHub challenge"
  type        = string
  default     = null
}

variable "trust_me_enabled" {
  description = "Enable or disable trust_me challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "opensearch_dynamodb_enabled" {
  description = "Enable or disable the open search dynamodb challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "furls1_enabled" {
  description = "Enable or disable furls1 challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}
variable "furls2_enabled" {
  description = "Enable or disable furls2 challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "secretsmanager_enabled" {
  description = "Enable or disable secretsmanager challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "github_pat_enabled" {
  description = "Enable or disable github_pat challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "search1and2_enabled" {
  description = "Enable or disable opensearch_github_pat challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "its_a_secret_enabled" {
  description = "Enable or disable its_a_secret challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "its_another_secret_enabled" {
  description = "Enable or disable its_another_secret challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "backwards_enabled" {
  description = "Enable or disable backwards challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "bastion_enabled" {
  description = "Enable or disable bastion challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "variable_enabled" {
  description = "Enable or disable variable challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "the_topic_is_exposure_enabled" {
  description = "Enable or disable the_topic_is_exposure challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "the_topic_is_execution_enabled" {
  description = "Enable or disable the_topic_is_execution challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "middle_enabled" {
  description = "Enable or disable middle challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "wyatt_enabled" {
  description = "Enable or disable wyatt challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
  }


variable "root_enabled" {
  description = "Enable or disable root challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}
variable "double_tap_enabled" {
  description = "Enable or disable double_tap challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}

variable "needles_enabled" {
  description = "Enable or disable double_tap challenge (true = enabled, false = disabled)"
  type        = bool
  default     = false
}