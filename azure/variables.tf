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