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

variable "account_id" {
  description = "This is the ID of the caller account"
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

variable "vpc_id" {
  type    = string
  default = ""
}

variable "subnet1_id" {
  type    = string
  default = ""
}

variable "subnet2_id" {
  type    = string
  default = ""
}

variable "subnet3_id" {
  type    = string
  default = ""
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

# Resources
resource "random_password" "database-secret" {
  length           = 31
  special          = true
  min_special      = 5
  override_special = "!#$%^&*()-_=+[]{}<>:?"
  keepers = {
    pass_version = 1
  }
}

resource "random_password" "app-secret" {
  length           = 31
  special          = true
  min_special      = 5
  override_special = "!#$%^&*()-_=+[]{}<>:?"
  keepers = {
    pass_version = 1
  }
}

resource "random_string" "resource-suffix" {
  length           = 5 
  upper = false 
  special = false
}

variable "user_ip" {
  description = "The current user's IP address"
  type        = string
  default     = ""
}

variable "ctf_starting_user_arn" {
  description = "The arn of the user that is created at the start of the CTF"
  type        = string
  default     = ""
}

variable "ctf_starting_user_name" {
  description = "The name of the user that is created at the start of the CTF"
  type        = string
  default     = ""
}

variable "aws_root_user" {
  description = "This is the root user of the calling account"
  type        = string
  default     = ""
}