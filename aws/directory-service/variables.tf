variable "namespace" {}
variable "environment" {}
variable "stage" {}
variable "master_account_id" {}
variable "account_id" {}

variable "repository" {
  default = "github.com/gravicore/terraform-gravicore-modules/aws/directory-service"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "tags" {
  default = {}
}

variable "directory_services_short_name" {}
variable "parent_domain_name" {}

variable "subnet_ids" {
  type        = "list"
  default     = []
  description = "The identifiers of the subnets for the directory servers (2 subnets in 2 different AZs)"
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

variable "dns_zone_name" {
  type        = "string"
  default     = "ds"
  description = "Name of the DNS zone managed by the directory service"
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
  default     = "CORP"
  description = "The short name of the directory, such as CORP."
}

variable "netbios_node_type" {
  type        = "string"
  default     = "2"
  description = "The NetBIOS node type (1, 2, 4, or 8). AWS recommends to specify 2 since broadcast and multicast are not supported in their network."
}
