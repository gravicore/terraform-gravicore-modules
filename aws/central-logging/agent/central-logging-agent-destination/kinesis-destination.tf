# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

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
  type = "string"
}

variable "master_account_id" {}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "retention_in_days" {
  description = "Number of days you want to retain log events in the log group"
  default     = "30"
}

variable "filter_pattern" {
  description = "Valid CloudWatch Logs filter pattern for subscribing to a filtered stream of log events"
  default     = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action, flowlogstatus]"
}

variable "enabled" {
  default     = "true"
  description = "Set to false to prevent the module from creating anything"
}

variable "account_id" {
  description = "Account number of the current account"
  default     = ""
}

variable "log_type" {
  description = "Type of log. IE flow_log"
}

variable terraform_module {
  default = "gravicore/terraform-gravicore-modules/aws/central-logging/agent/central-logging-agent-destination"
}

data "terraform_remote_state" "master_acct" {
  backend = "s3"

  config {
    region         = "${var.aws_region}"
    bucket         = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt        = true
    key            = "master/prd/acct/terraform.tfstate"
    dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/${var.master_account_assume_role_name}"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudformation_stack" "aws_central_logging_destination" {
  count        = "${var.enabled == "true" ? 1 : 0}"
  provider     = "aws.master"
  name         = "log-destination-${var.account_id}-${var.log_type}"
  capabilities = ["CAPABILITY_IAM"]

  parameters {
    LogBucketName       = "${data.terraform_remote_state.master_acct.log_bucket_name}"
    LogS3Location       = "${var.account_id}/${var.log_type}"
    ProcessingLambdaARN = "${data.terraform_remote_state.master_acct.central_logging_lambda}"
    SourceAccount       = "${var.account_id}"
  }

  template_body = "${file("${path.module}/cloudformation/aws-central-logging-destination.cft")}"
}

resource "aws_cloudwatch_log_group" "default" {
  count             = "${var.enabled == "true" ? 1 : 0}"
  name              = "${local.stage_prefix}-${var.log_type}"
  retention_in_days = "${var.retention_in_days}"
  tags              = "${local.tags}"
}

resource "aws_cloudwatch_log_subscription_filter" "default" {
  count           = "${var.enabled == "true" ? 1 : 0}"
  name            = "${local.stage_prefix}-${var.log_type}"
  log_group_name  = "${aws_cloudwatch_log_group.default.name}"
  filter_pattern  = "${var.filter_pattern}"
  destination_arn = "${aws_cloudformation_stack.aws_central_logging_destination.outputs["Destination"]}"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "log_group_name" {
  value       = "${element(concat(aws_cloudwatch_log_group.default.*.name, list("")), 0)}"
  description = "ARN of the log group"
}

output "log_group_arn" {
  value       = "${element(concat(aws_cloudwatch_log_group.default.*.arn, list("")), 0)}"
  description = "The log group's Amazon Resource Name (ARN) specifying the log group"
}

output "destination_arn" {
  value       = "${element(concat(aws_cloudformation_stack.aws_central_logging_destination.*.outputs, list("")), 0)}"
  description = "The kinesis destination's Amazon Resource Name (ARN) specifying the log group"
}
