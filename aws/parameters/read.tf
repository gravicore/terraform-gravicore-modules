# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "parameters" {
  description = "A list of SSM Parameters to fetch"
  type        = list(any)
  default     = []
}

variable "merge" {
  type = object({
    source = string
    target = string
    ignore = optional(list(string), [])
  })
  default = null
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "aws_ssm_parameter" "source_params" {
  for_each = var.create ? toset(local.source_parameters) : []
  name     = split(":::", each.value)[0]
}

locals {
  source_parameters = var.merge != null ? [for v in var.parameters : replace(v, var.merge.target, var.merge.source)] : var.parameters

  source_string_parameters = { for k, v in data.aws_ssm_parameter.source_params : k => v if v.type == "String" }
  source_secret_parameters = { for k, v in data.aws_ssm_parameter.source_params : k => v if v.type == "SecureString" }
  source_list_parameters   = { for k, v in data.aws_ssm_parameter.source_params : k => merge(v, { value = split(",", v.value) }) if v.type == "StringList" }

  targets = { for k, v in jsondecode(
    var.merge != null ? jsonencode(merge(
      local.source_string_parameters,
      local.source_list_parameters,
      local.source_secret_parameters,
    )) : jsonencode({})) : replace(k, var.merge.source, var.merge.target) => v
  if try(contains(var.merge.ignore, replace(k, var.merge.source, var.merge.target)) == false, false) }

  target_parameters = try(nonsensitive([for k, v in local.targets : k]), [])

  target_string_parameters = { for k, v in data.aws_ssm_parameter.target_params : k => v if v.type == "String" }
  target_secret_parameters = { for k, v in data.aws_ssm_parameter.target_params : k => v if v.type == "SecureString" }
  target_list_parameters   = { for k, v in data.aws_ssm_parameter.target_params : k => merge(v, { value = split(",", v.value) }) if v.type == "StringList" }

  string_parameters = var.merge != null ? local.target_string_parameters : local.source_string_parameters
  secret_parameters = var.merge != null ? local.target_secret_parameters : local.source_secret_parameters
  list_parameters   = var.merge != null ? local.target_list_parameters : local.source_list_parameters
}

resource "aws_ssm_parameter" "target" {
  for_each  = try(nonsensitive(local.targets), {})
  name      = each.key
  type      = each.value.type
  value     = each.value.type == "StringList" ? join(",", tolist(each.value.value)) : tostring(each.value.value)
  overwrite = true
  tags      = local.tags
}

data "aws_ssm_parameter" "target_params" {
  for_each   = var.create ? toset(var.parameters) : []
  name       = split(":::", each.value)[0]
  depends_on = [aws_ssm_parameter.target]
}

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
