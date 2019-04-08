# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "cloudwatch_log_groups" {
  description = "A list of CloudWatch Log Groups to create for association with the Datadog lambda agent."
  type        = "list"
  default     = ["vpc"]
}

variable "datadog_api_key" {
  description = ""
}

locals {
  lambda_function_name = "lambda_datadog_logging"
}

# resource "null_resource" "datadog_lambda" {
#   provisioner "local-exec" {
#     command = "curl -LJo ${path.module}/datadog_lambda_function.py https://raw.githubusercontent.com/DataDog/datadog-serverless-functions/master/aws/logs_monitoring/lambda_function.py"
#   }
# }

provider "archive" {}

data "archive_file" "logging_lambda" {
  count = "${var.create == "true" ? 1 : 0}"

  type        = "zip"
  source_file = "${path.module}/${local.lambda_function_name}.py"
  output_path = "${path.module}/${local.lambda_function_name}.zip"
}

data "aws_iam_policy_document" "logging_lambda" {
  count = "${var.create == "true" ? 1 : 0}"

  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "logging_assume" {
  count = "${var.create == "true" ? 1 : 0}"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "logging_log_groups" {
  count = "${var.create == "true" ? 1 : 0}"

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

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

locals {
  module_kms_key_tags = "${merge(local.tags, map(
    "TerraformModule", "cloudposse/terraform-aws-kms-key",
    "TerraformModuleVersion", "0.1.2"))}"
}

module "logging_kms_key" {
  source      = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace   = ""
  stage       = ""
  name        = "${local.stage_prefix}-datadog"
  description = "${join(" ", list(var.desc_prefix, "KMS key for Datadog"))}"
  tags        = "${local.module_kms_key_tags}"

  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/${replace(local.stage_prefix, "-", "/")}/datadog"
}

resource "aws_iam_role" "logging" {
  count       = "${var.create == "true" ? 1 : 0}"
  name        = "${local.module_prefix}-logging"
  description = "${var.desc_prefix} Enables the pushing of logs from S3, CloudWatch and CloudTrail to Datadog"
  tags        = "${local.tags}"

  assume_role_policy = "${data.aws_iam_policy_document.logging_lambda.json}"
}

resource "aws_iam_role_policy_attachment" "logging_aws_lambda_basic_execution" {
  count = "${var.create == "true" ? 1 : 0}"

  role       = "${aws_iam_role.logging.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "logging_log_groups" {
  count       = "${var.create == "true" ? 1 : 0}"
  name        = "${local.module_prefix}-logging-log-groups"
  description = "${var.desc_prefix} Allows AWS services to push to Datadog CloudWatch Log Groups"
  tags        = "${local.tags}"

  assume_role_policy = "${data.aws_iam_policy_document.logging_assume.json}"
}

resource "aws_iam_role_policy" "logging_log_groups" {
  count = "${var.create == "true" ? 1 : 0}"
  name  = "${local.module_prefix}-logging-log-groups"

  role   = "${aws_iam_role.logging_log_groups.id}"
  policy = "${data.aws_iam_policy_document.logging_log_groups.json}"
}

resource "aws_cloudwatch_log_group" "logging" {
  count = "${var.create == "true" ? length(var.cloudwatch_log_groups) : 0}"
  name  = "/aws/${element(var.cloudwatch_log_groups, count.index)}/${local.module_prefix}"
  tags  = "${local.tags}"

  # kms_key_id = "${module.logging_kms_key.key_arn}"
  retention_in_days = "30"
}

resource "aws_lambda_function" "logging" {
  count         = "${var.create == "true" ? 1 : 0}"
  function_name = "${local.module_prefix}-lambda"
  tags          = "${local.tags}"

  filename         = "${data.archive_file.logging_lambda.output_path}"
  source_code_hash = "${data.archive_file.logging_lambda.output_base64sha256}"
  kms_key_arn      = "${module.logging_kms_key.key_arn}"

  role    = "${aws_iam_role.logging.arn}"
  handler = "${local.lambda_function_name}.lambda_handler"
  runtime = "python2.7"
  timeout = 10

  environment {
    variables = {
      DD_API_KEY = "${var.datadog_api_key}"
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count = "${var.create == "true" ? length(var.cloudwatch_log_groups) : 0}"

  statement_id  = "${local.module_prefix}-allow-cloudwatch-${element(var.cloudwatch_log_groups, count.index)}"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.logging.arn}"
  principal     = "logs.us-east-1.amazonaws.com"
  source_arn    = "${element(aws_cloudwatch_log_group.logging.*.arn, count.index)}"
}

resource "aws_cloudwatch_log_subscription_filter" "logging" {
  depends_on = ["aws_lambda_permission.allow_cloudwatch"]
  count      = "${var.create == "true" ? length(var.cloudwatch_log_groups) : 0}"
  name       = "${local.module_prefix}-${element(var.cloudwatch_log_groups, count.index)}"

  destination_arn = "${join("", aws_lambda_function.logging.*.arn)}"
  log_group_name  = "/aws/${element(var.cloudwatch_log_groups, count.index)}/${local.module_prefix}"
  filter_pattern  = ""
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# output "logging_" {
#   value       = ""
#   description = ""
# }

output "kms_key_arn" {
  value       = "${module.logging_kms_key.key_arn}"
  description = "The ARN for the KMS encryption key."
}

output "logging_lambda_function_arn" {
  value       = "${join("", aws_lambda_function.logging.*.arn)}"
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function."
}

output "logging_log_groups_arns" {
  value       = "${aws_cloudwatch_log_group.logging.*.arn}"
  description = ""
}
