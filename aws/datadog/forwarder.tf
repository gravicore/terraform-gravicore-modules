# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "datadog_forwarder_version" {
  description = "Version of the Datadog forwarder to use"
  default     = ""
}

locals {
  datadog_forwarder_version = coalesce(var.datadog_forwarder_version, "latest")
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Datadog Forwarder to ship logs from S3 and CloudWatch, as well as observability data from Lambda functions to Datadog.
# https://github.com/DataDog/datadog-serverless-functions/tree/master/aws/logs_monitoring
resource "aws_cloudformation_stack" "datadog_forwarder" {
  count = var.create ? 1 : 0
  name  = join("-", [local.module_prefix, "forwarder"])
  tags  = local.tags

  template_url = "https://datadog-cloudformation-template.s3.amazonaws.com/aws/forwarder/${local.datadog_forwarder_version}.yaml"
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]
  parameters = {
    FunctionName      = join("-", [local.module_prefix, "forwarder"])
    DdApiKey          = "this_value_is_not_used"
    DdApiKeySecretArn = aws_secretsmanager_secret.datadog_api_key.arn
    DdTags            = join(",", [for k, v in local.tags : format("%s:%s", k, v)])
  }

  depends_on = [aws_cloudformation_stack.datadog_integration]
  lifecycle {
    ignore_changes = [
      parameters["DdApiKey"]
    ]
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "datadog_forwarder_arn" {
  value = aws_cloudformation_stack.datadog_forwarder[0].outputs.DatadogForwarderArn
}


# ---

variable "datadog_cloudwatch_log_groups" {
  description = "A list of CloudWatch Log Groups to create for association with the Datadog lambda agent."
  type        = list(string)
  default     = []
}

# data "aws_lambda_function" "datadog_forwarder" {
#   count = var.create ? 1 : 0
#   function_name = split(":", aws_cloudformation_stack.datadog_forwarder[0].outputs.DatadogForwarderArn)[7]
# }

resource "aws_lambda_permission" "allow_cloudwatch" {
  count = var.create ? length(var.datadog_cloudwatch_log_groups) : 0

  # statement_id  = "${local.module_prefix}-allow-cloudwatch-${count.index}"
  action        = "lambda:InvokeFunction"
  function_name = aws_cloudformation_stack.datadog_forwarder[0].outputs.DatadogForwarderArn
  principal     = "logs.${var.aws_region}.amazonaws.com"
  source_arn    = "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:${element(var.datadog_cloudwatch_log_groups, count.index)}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "logging" {
  count = var.create ? length(var.datadog_cloudwatch_log_groups) : 0
  name  = join("-", [local.module_prefix, "forwarder", count.index])

  destination_arn = aws_cloudformation_stack.datadog_forwarder[0].outputs.DatadogForwarderArn
  log_group_name  = element(var.datadog_cloudwatch_log_groups, count.index)
  filter_pattern  = ""

  depends_on = [
    aws_cloudformation_stack.datadog_forwarder,
    aws_lambda_permission.allow_cloudwatch
  ]
}

output "datadog_cloudwatch_trigger_arns" {
  description = "ARNs of the destination to deliver matching log events to. Kinesis stream or Lambda function ARN."
  value       = [for log_group_name in aws_cloudwatch_log_subscription_filter.logging.*.log_group_name : "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:${log_group_name}:*"]
}

