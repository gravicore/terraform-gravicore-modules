# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "datasync_agent_activation_key" {
  description = "Activation Key of the DataSync Agent"
  type        = string
  default     = null
}

variable "datasync_agent_id" {
  description = "ID of the DataSync Agent"
  type        = string
  default     = null
}

variable "datasync_agent_arn" {
  description = "ARN of the DataSync Agent"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# CloudWatch Log Group

resource "aws_cloudwatch_log_group" "datasync" {
  count = var.create && var.datasync_agent_id != null ? 1 : 0
  name  = "/aws/datasync/${local.module_prefix}"
  tags  = local.tags

  retention_in_days = var.cloudwatch_log_group_retention_in_days
  # kms_key_id = 
}

# DataSync agent
# TODO: Add VPC endpoint to DataSync Agent resource when it becomes available
# resource "aws_datasync_agent" "datasync" {
#   count = var.create ? 1 : 0
#   name  = "${local.module_prefix}-datasync"
#   tags  = local.tags

#   ip_address = module.datasync_ec2.private_ip[0]
#   timeouts {
#     create = "2m"
#   }
# }

locals {
  datasync_agent_arn = var.create && var.datasync_agent_id != null ? "arn:aws:datasync:${var.aws_region}:${local.account_id}:agent/${var.datasync_agent_id}" : var.datasync_agent_arn != null ? var.datasync_agent_arn : null
}


# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "datasync_agent_activation_key" {
  description = "Activation Key of the DataSync Agent"
  value       = var.create ? var.datasync_agent_activation_key : null
}

output "datasync_agent_id" {
  description = "ID of the DataSync Agent"
  value       = var.create ? var.datasync_agent_id : null
  # value = aws_datasync_agent.datasync[0].arn
}

output "datasync_agent_arn" {
  description = "ARN of the DataSync Agent"
  value       = coalesce(var.datasync_agent_arn, local.datasync_agent_arn, "")
}
