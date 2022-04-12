# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "directory_dns_name" {
  description = "(Required) The fully qualified name for the directory, such as corp.example.com"
  default     = null
  type        = string
}

variable "password" {
  description = "(Required) The password for the directory administrator or connector user"
  default     = null
  type        = string
}

variable "password_parameter_key" {
  description = "(Optional) SSM parameter key of stored password"
  default     = null
  type        = string
}

variable "username_parameter_key" {
  description = "(Optional) SSM parameter key of stored username"
  default     = null
  type        = string
}

variable "size" {
  description = "(Required for SimpleAD and ADConnector) The size of the directory (Small or Large are accepted values)"
  type        = string
  default     = "Small"
}

variable "subnet_ids" {
  description = "(Required) The identifiers of the subnets for the directory servers (2 subnets in 2 different AZs)"
  type        = list(string)
}

variable "connect_settings_customer_username" {
  description = "(Required for ADConnector) The username corresponding to the password provided"
  type        = string
  default     = null
}

variable "connect_settings_customer_dns_ips" {
  description = "(Required for ADConnector) The DNS IP addresses of the domain to connect to"
  type        = list(string)
  default     = null
}

variable "alias" {
  description = "(Optional) The alias for the directory (must be unique amongst all aliases in AWS). Required for enable_sso"
  type        = string
  default     = null
}

variable "description" {
  description = "(Optional) A textual description for the directory"
  type        = string
  default     = null
}

variable "short_name" {
  description = "(Optional) The short name of the directory, such as CORP"
  type        = string
  default     = null
}

variable "enable_sso" {
  description = "(Optional) Whether to enable single-sign on for the directory. Requires alias. Defaults to false"
  default     = false
}

variable "type" {
  description = "(Optional) - The directory type (SimpleAD, ADConnector or MicrosoftAD are accepted values). Defaults to SimpleAD"
  type        = string
  default     = "SimpleAD"
}

variable "edition" {
  description = "(Optional) The MicrosoftAD edition (Standard or Enterprise). Defaults to Enterprise (applies to MicrosoftAD type only)"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "aws_subnet" "default" {
  count = var.create && var.subnet_ids != null ? 1 : 0
  id    = var.subnet_ids[0]
}

data "aws_ssm_parameter" "password" {
  count = var.create && var.password_parameter_key != null ? 1 : 0
  name  = var.password_parameter_key
}

data "aws_ssm_parameter" "username" {
  count = var.create && var.username_parameter_key != null ? 1 : 0
  name  = var.username_parameter_key
}

resource "aws_directory_service_directory" "default" {
  count       = var.create ? 1 : 0
  name        = var.directory_dns_name
  short_name  = var.short_name
  password    = var.password_parameter_key != null ? concat(data.aws_ssm_parameter.password.*.value, [""])[0] : var.password
  size        = var.size
  type        = var.type
  alias       = var.alias
  description = var.description
  enable_sso  = var.enable_sso
  edition     = var.edition
  tags        = var.tags

  dynamic "vpc_settings" {
    for_each = var.type != "ADConnector" ? ["1"] : []
    content {
      subnet_ids = var.subnet_ids
      vpc_id     = concat(data.aws_subnet.default.*.vpc_id, [""])[0]
    }
  }

  dynamic "connect_settings" {
    for_each = var.type == "ADConnector" ? ["1"] : []
    content {
      customer_dns_ips  = var.connect_settings_customer_dns_ips
      customer_username = var.username_parameter_key != null ? concat(data.aws_ssm_parameter.username.*.value, [""])[0] : var.connect_settings_customer_username
      subnet_ids        = var.subnet_ids
      vpc_id            = concat(data.aws_subnet.default.*.vpc_id, [""])[0]
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "id" {
  description = "The ID of the directory"
  value       = concat(aws_directory_service_directory.default.*.id, [""])[0]
}

output "access_url" {
  description = "The access URL for the directory"
  value       = concat(aws_directory_service_directory.default.*.access_url, [""])[0]
}

output "dns_ip_addresses" {
  description = "A list of IP addresses of the DNS servers for the directory or connector"
  value       = concat(aws_directory_service_directory.default.*.dns_ip_addresses, [""])[0]
}

output "security_group_id" {
  description = "The ID of the security group created by the directory"
  value       = concat(aws_directory_service_directory.default.*.security_group_id, [""])[0]
}
