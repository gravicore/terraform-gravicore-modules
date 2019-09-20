# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "create" {
  description = "Whether to create this resource or not?"
  default     = true
}

variable "stage_prefix" {
  description = "Creates a unique name beginning with the specified prefix"
}

variable "family" {
  description = "The family of the DB parameter group"
}

variable "parameters" {
  description = "A list of DB parameter maps to apply"
  default     = []
  type        = list(map(string))
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource"
  default     = {}
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_db_parameter_group" "this" {
  count = var.create ? 1 : 0

  name        = var.stage_prefix
  description = "Default database parameter group"
  family      = var.family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", null)
    }
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Default parameter group"
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "this_db_parameter_group_id" {
  description = "The db parameter group id"
  value       = element(split(",", join(",", aws_db_parameter_group.this.*.id)), 0)
}

output "this_db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = element(split(",", join(",", aws_db_parameter_group.this.*.arn)), 0)
}

