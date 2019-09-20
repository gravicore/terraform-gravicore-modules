# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "terraform_remote_state_key" {
  description = "Key for the location of the remote state of the master account module"
}

variable "namespace" {
  description = "Namespace (e.g. `grv` or `gravicore`)"
  type        = string
}

variable "stage" {
  description = "Stage (e.g. `prod`, `uat`, `dev`)"
  type        = string
}

variable "environment" {
  description = "Environment (e.g. `master`)"
  type        = string
}

variable "repository" {
  type = string
}

variable "master_account_id" {
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "enabled" {
  default     = "true"
  description = "Set to false to prevent the module from creating anything"
}

variable "account_id" {
  description = "Account number of the current account"
  default     = ""
}

variable "terraform_module" {
  default = "gravicore/terraform-gravicore-modules/aws/central-logging/agent"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "log_assume" {
  count = var.enabled == "true" ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "log" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "log" {
  count  = var.enabled == "true" ? 1 : 0
  name   = "${local.stage_prefix}-vpc-flow-logs"
  role   = aws_iam_role.log[0].id
  policy = data.aws_iam_policy_document.log.json
}

resource "aws_iam_role" "log" {
  count              = var.enabled == "true" ? 1 : 0
  name               = "${local.stage_prefix}-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.log_assume[0].json
}

module "flow_log_destination" {
  source = "./central-logging-agent-destination"

  master_account_assume_role_name = var.master_account_assume_role_name
  terraform_remote_state_key      = var.terraform_remote_state_key
  namespace                       = var.namespace
  environment                     = var.environment
  stage                           = var.stage
  enabled                         = var.enabled
  master_account_id               = var.master_account_id
  account_id                      = var.account_id
  repository                      = var.repository
  log_type                        = "flow-logs"
  filter_pattern                  = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action, flowlogstatus]"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "flow_log_group_name" {
  value       = module.flow_log_destination.log_group_name
  description = "Name of the flow log log group"
}

output "log_group_iam_role_arn" {
  value       = element(concat(aws_iam_role.log.*.arn, [""]), 0)
  description = "The Amazon Resource Name (ARN) specifying the role"
}

output "log_group_iam_role_unique_id" {
  value       = element(concat(aws_iam_role.log.*.unique_id, [""]), 0)
  description = "The stable and unique string identifying the role"
}

output "log_group_iam_role_name" {
  value       = element(concat(aws_iam_role.log.*.name, [""]), 0)
  description = "The name of the role."
}

output "flow_log_group_arn" {
  value       = module.flow_log_destination.log_group_arn
  description = "The flow log log group's Amazon Resource Name (ARN) specifying the log group"
}

output "flow_log_destination_arn" {
  value       = module.flow_log_destination.destination_arn
  description = "The kinesis destination's Amazon Resource Name (ARN) specifying the log group"
}

