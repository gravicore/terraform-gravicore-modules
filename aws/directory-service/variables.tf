variable "vpc_id" {
  type        = "string"
  description = "The fully qualified name for the directory, such as corp.example.com"
}

variable "subnet_ids" {
  type        = "list"
  default     = []
  description = "The identifiers of the subnets for the directory servers (2 subnets in 2 different AZs)"
}

variable "name" {
  type        = "string"
  description = "The fully qualified name for the directory, such as corp.example.com"
}

variable "password" {
  type        = "string"
  description = "The fully qualified name for the directory, such as corp.example.com"
}

variable "edition" {
  type        = "string"
  default     = "Standard"
  description = "The MicrosoftAD edition (Standard or Enterprise). Defaults to Enterprise (applies to MicrosoftAD type only)"
}

variable "type" {
  type        = "string"
  default     = "MicrosoftAD"
  description = "The directory type (SimpleAD, ADConnector or MicrosoftAD are accepted values)"
}

variable "enable_sso" {
  type        = "string"
  default     = "false"
  description = "Whether to enable single-sign on for the directory. Requires alias."
}

variable "alias" {
  type        = "string"
  default     = ""
  description = "The alias for the directory (must be unique amongst all aliases in AWS). Required for enable_sso"
}

variable "short_name" {
  type        = "string"
  default     = ""
  description = "The short name of the directory, such as CORP."
}

variable "namespace" {}
variable "environment" {}
variable "stage" {}
variable "master_account_id" {}
variable "account_id" {}
variable "repository" {}
variable "directory_services_short_name" {}
variable "parent_domain_name" {}

variable "aws_region" {
  default = "us-east-1"
}

variable "tags" {
  default = {}
}
