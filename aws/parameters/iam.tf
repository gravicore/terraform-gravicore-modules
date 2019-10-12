# # ----------------------------------------------------------------------------------------------------------------------
# # VARIABLES / LOCALS / REMOTE STATE
# # ----------------------------------------------------------------------------------------------------------------------

# variable allow_gravicore_access {
#   description = "Flag to establish SAML connectivity for Gravicore managed services"
#   default     = false
# }

# variable "role_max_session_duration" {
#   type        = number
#   default     = 43200
#   description = "The maximum session duration (in seconds) that you want to set for the specified role. If you do not specify a value for this setting, the default maximum of one hour is applied. This setting can have a value from 1 hour to 12 hours."
# }

# variable "trusted_account_ids" {
#   type        = list(string)
#   default     = []
#   description = ""
# }

# locals {
#   trusted_account_ids = coalescelist(var.trusted_account_ids, [local.account_id])
# }

# # ----------------------------------------------------------------------------------------------------------------------
# # MODULES / RESOURCES
# # ----------------------------------------------------------------------------------------------------------------------

# data "template_file" "assume_role_policy" {
#   count = var.create && length(var.write_parameters) > 0 ? 1 : 0

#   vars     = {}
#   template = <<TEMPLATE
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": "arn:aws:iam::${local.account_id}:root"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# TEMPLATE
# }

# data "aws_iam_policy_document" "trusted_entities" {
#   count = var.create && length(var.write_parameters) > 0 ? 1 : 0

#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "AWS"
#       identifiers = local.trusted_account_ids
#     }
#   }
#   #   statement {
#   #     actions = ["sts:AssumeRoleWithSAML"]
#   #     principals {
#   #       type        = "Federated"
#   #       identifiers = local.federated_trusted_entities
#   #     }
#   #   }
# }

# data "aws_iam_policy_document" "parameters" {
#   count = var.create && length(var.write_parameters) > 0 ? 1 : 0

#   statement {
#     actions   = ["ssm:DescribeParameters"]
#     resources = ["*"]
#   }
#   statement {
#     actions = ["ssm:GetParameters"]
#     resources = [
#       "arn:aws:ssm:${var.aws_region}:${local.account_id}:parameter/${local.stage_prefix}/*",
#     ]
#   }
# }

# resource "aws_iam_role" "parameters" {
#   count = var.create && length(var.write_parameters) > 0 ? 1 : 0
#   name  = join(var.delimiter, [var.namespace, "parameters"])
#   tags  = local.tags

#   assume_role_policy   = data.template_file.assume_role_policy[0].rendered
#   max_session_duration = var.role_max_session_duration
# }

# resource "aws_iam_role_policy" "parameters" {
#   count = var.create && length(var.write_parameters) > 0 ? 1 : 0
#   name  = replace("${var.namespace}-parameter-access", "-", var.delimiter)

#   role   = aws_iam_role.parameters[0].name
#   policy = data.aws_iam_policy_document.parameters[0].json
# }
