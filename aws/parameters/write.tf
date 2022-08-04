# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "write_parameters" {
  description = <<DESC
Map of parameters to write to the SSM Parameter store. Example:
    { "/grv-shared-dev/rds-postgres-password" = {   // Required - The name of the parameter. If the name contains a path (e.g. any forward slashes (/)), it must be fully qualified with a leading forward slash (/).
        value = "password1" // Required - The value of the parameter
        type = "SecureString" // Optional - Valid types are String, StringList and SecureString
        description = "Production database master password" // Optional - The description of the parameter
        overwrite = false // Optional - Force Overwrite of value if true
        allowed_pattern = "" // Optional - A regular expression used to validate the parameter value
    } }
DESC
  type        = map(any)
  default     = {}
}

variable "kms_arn" {
  type        = string
  default     = ""
  description = "The ARN of a KMS key used to encrypt and decrypt SecretString values"
}

data "aws_kms_key" "kms" {
  for_each = var.create && var.kms_arn == "" ? toset(["0"]) : []
  key_id   = "alias/parameter_store_key"
}

locals {
  kms_arn          = coalesce(var.kms_arn, data.aws_kms_key.kms["0"].key_id, "")
  write_parameters = [for k, v in var.write_parameters : merge({ name = k }, v) if v.value != ""]
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_ssm_parameter" "write_parameters" {
  count = var.create ? length(local.write_parameters) : 0
  # for_each    = var.create ? { for k, v in var.write_parameters : k => v if v.value != "" } : {}
  name        = local.write_parameters[count.index].name
  description = format("%s %s", var.desc_prefix, lookup(local.write_parameters[count.index], "description", local.write_parameters[count.index].name))
  tags        = var.tags

  type            = lookup(local.write_parameters[count.index], "type", "String")
  key_id          = lookup(local.write_parameters[count.index], "type", "String") == "SecureString" ? local.kms_arn : null
  value           = local.write_parameters[count.index].value
  overwrite       = lookup(local.write_parameters[count.index], "overwrite", true)
  allowed_pattern = lookup(local.write_parameters[count.index], "allowed_pattern", "")
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "write_parameters" {
  description = "Map of SSM parameters that have been written to the store"
  value       = aws_ssm_parameter.write_parameters
  sensitive   = true
}
