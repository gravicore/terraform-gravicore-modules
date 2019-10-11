# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "parameters" {
  description = "A list of SSM Parameters to fetch"
  type        = list
  default     = []
}
provider "aws" {}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "aws_ssm_parameter" "params" {
  for_each = var.create ? toset(var.parameters) : []
  name     = split(":::", each.value)[0]
}

locals {
  string_parameters = { for k, v in data.aws_ssm_parameter.params : k => v if v.type == "String" }
  secret_parameters = { for k, v in data.aws_ssm_parameter.params : k => v if v.type == "SecureString" }
  list_parameters   = { for k, v in data.aws_ssm_parameter.params : k => merge(v, { value = split(",", v.value) }) if v.type == "StringList" }
}

# resource "aws_ssm_parameter" "default" {
#   count           = "${var.enabled == "true" ? length(var.parameter_write) : 0}"
#   name            = "${lookup(var.parameter_write[count.index], "name")}"
#   description     = "${lookup(var.parameter_write[count.index], "description", lookup(var.parameter_write[count.index], "name"))}"
#   type            = "${lookup(var.parameter_write[count.index], "type", "SecureString")}"
#   key_id          = "${lookup(var.parameter_write[count.index], "type", "SecureString") == "SecureString" && length(var.kms_arn) > 0 ? var.kms_arn : ""}"
#   value           = "${lookup(var.parameter_write[count.index], "value")}"
#   overwrite       = "${lookup(var.parameter_write[count.index], "overwrite", "false")}"
#   allowed_pattern = "${lookup(var.parameter_write[count.index], "allowed_pattern", "")}"
#   tags            = "${var.tags}"
# }

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "parameters" {
  description = ""
  value = merge(
    local.string_parameters,
    local.list_parameters,
    local.secret_parameters,
  )
}

output "string_parameters" {
  description = "Map of the requested String SSM Parameters"
  value       = local.string_parameters
}

output "secret_parameters" {
  description = "Map of the requested SecretString SSM Parameters"
  value       = local.secret_parameters
}

output "list_parameters" {
  description = "Map of the requested List SSM Parameters"
  value       = local.list_parameters
}
