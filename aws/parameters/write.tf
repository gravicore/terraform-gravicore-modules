# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "write_parameters" {
  description = <<DESC
Map of parameters to write to the SSM Parameter store. Example:
    { "/grv-shared-dev/rds-postgres-password" = {   // Required - The name of the parameter. If the name contains a path (e.g. any forward slashes (/)), it must be fully qualified with a leading forward slash (/).
        type = "SecureString" // Required - Valid types are String, StringList and SecureString
        value = "password1" // Required - The value of the parameter
        description = "Production database master password" // Optional - The description of the parameter
        overwrite = false // Optional - Force Overwrite of value if true
        allowed_pattern = "" // Optional - A regular expression used to validate the parameter value
    } }
DESC
  type        = map
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
  kms_arn = coalesce(var.kms_arn, data.aws_kms_key.kms["0"].key_id, "")
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_ssm_parameter" "write_parameters" {
  for_each    = var.create ? var.write_parameters : {}
  name        = each.key
  description = format("%s %s", var.desc_prefix, lookup(each.value, "description", each.key))
  tags        = var.tags

  type            = "${lookup(each.value, "type", "String")}"
  key_id          = lookup(each.value, "type", "SecureString") == "SecureString" ? local.kms_arn : ""
  value           = each.value.value
  overwrite       = "${lookup(each.value, "overwrite", true)}"
  allowed_pattern = "${lookup(each.value, "allowed_pattern", "")}"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "write_parameters" {
  value       = aws_ssm_parameter.write_parameters
  description = ""
}