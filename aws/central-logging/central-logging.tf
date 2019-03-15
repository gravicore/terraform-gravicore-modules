# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "tags" {
  default = {}
}

variable "name" {
  default     = "central-logging"
  description = "Name  (e.g. `bastion` or `db`)"
}

variable "namespace" {
  description = "Namespace (e.g. `grv` or `gravicore`)"
  type        = "string"
}

variable "stage" {
  description = "Stage (e.g. `prod`, `uat`, `dev`)"
  type        = "string"
}

variable "environment" {
  description = "Environment (e.g. `master`)"
  type        = "string"
}

variable "repository" {
  default = ""
}

variable terraform_module {
  default = "gravicore/terraform-gravicore-modules/aws/central-logging"
}

variable "master_account_id" {}
variable "account_id" {}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "log_storage" {
  source    = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=0.3.0"
  enabled   = "${local.is_master == 1 ? true : false }"
  name      = "${var.name}"
  namespace = "${local.environment_prefix}"
  stage     = "${var.stage}"
}

resource "aws_cloudformation_stack" "aws_central_logging_lambda" {
  count         = "${local.is_master}"
  name          = "${local.module_prefix}-lambda"
  capabilities  = ["CAPABILITY_IAM"]
  template_body = "${file("${path.module}/cloudformation/aws-central-logging-lambda.cft")}"
}

module "central_logging_agent" {
  source = "./agent"

  master_account_assume_role_name = "${var.master_account_assume_role_name}"
  enabled                         = "${local.is_child == 1 ? true : false }"
  namespace                       = "${var.namespace}"
  environment                     = "${var.environment}"
  stage                           = "${var.stage}"
  master_account_id               = "${var.master_account_id}"
  repository                      = "${var.repository}"
  account_id                      = "${var.account_id}"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "log_bucket_name" {
  value       = "${module.log_storage.bucket_id}"
  description = "Name of the logging bucket"
}

output "central_logging_lambda" {
  value       = "${element(concat(aws_cloudformation_stack.aws_central_logging_lambda.*.outputs, list("")), 0)}"
  description = "ARN of the central logging lambda"
}

output "flow_log_group_name" {
  value       = "${module.central_logging_agent.flow_log_group_name}"
  description = "ARN of the log group"
}

output "log_group_iam_role_arn" {
  value       = "${module.central_logging_agent.log_group_iam_role_arn}"
  description = "ARN of the log group"
}

output "log_group_iam_role_unique_id" {
  value       = "${module.central_logging_agent.log_group_iam_role_unique_id}"
  description = "The stable and unique string identifying the role"
}

output "log_group_iam_role_name" {
  value       = "${module.central_logging_agent.log_group_iam_role_name}"
  description = "The name of the role."
}

output "flow_log_group_arn" {
  value       = "${module.central_logging_agent.flow_log_group_arn}"
  description = "The flow log log group's Amazon Resource Name (ARN) specifying the log group"
}

output "flow_log_destination_arn" {
  value       = "${module.central_logging_agent.flow_log_destination_arn}"
  description = "The kinesis destination's Amazon Resource Name (ARN) specifying the log group"
}
