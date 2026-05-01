variable "azure_region" {
  description = "The Azure region to deploy to"
  type        = string
  default     = "westus2"
}

variable "subscription_id" {
  type = string
}

variable "domain" {
  type = string
}

variable "notsosecret_enabled" {
  type    = bool
  default = true
}

variable "permisery_enabled" {
  type    = bool
  default = true
}

variable "imageination_enabled" {
  type    = bool
  default = false
}

variable "vmiam_enabled" {
  type    = bool
  default = false
}

variable "cloudjumping_enabled" {
  type    = bool
  default = false
}