# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "cognito_user_pool_id" {
  description = "The Cognito User Pool ID"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "The domain name to associate with the AppAsync API."
  type        = string
}

variable "subdomain_name" {
  description = "The subdomain name to associate with the AppAsync API."
  type        = string
}

variable "certificate_arn" {
  type        = string
  description = "The certificate to associate with the Custom Domain."
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

locals {
  execution_role_arn = var.create ? aws_iam_role.this[0].arn : ""
}

resource "aws_iam_role" "this" {
  count = var.create ? 1 : 0
  name  = local.module_prefix

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "appsync.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "this" {
  count  = var.create ? 1 : 0
  name   = local.module_prefix
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.this[0].json
}

data "aws_iam_policy_document" "this" {
  count = var.create ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${local.account_id}:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["appsync:SourceGraphQL"]
    resources = ["arn:aws:appsync:${var.aws_region}:${local.account_id}:apis/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["appsync:StartSchemaMerge"]
    resources = ["arn:aws:appsync:${var.aws_region}:${local.account_id}:apis/*/sourceApiAssociations/*"]
  }
}

resource "gravicore_aws_appsync_graphql_api" "default" {
  count               = var.create ? 1 : 0
  name                = local.module_prefix
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  api_type            = "MERGED"
  tags                = var.tags
  xray_enabled        = true

  merged_api_execution_role_arn = local.execution_role_arn

  user_pool_config {
    user_pool_id   = var.cognito_user_pool_id
    aws_region     = var.aws_region
    default_action = "ALLOW"
  }

  enhanced_metrics_config {
    resolver_level_metrics_behavior    = "PER_RESOLVER_METRICS"
    data_source_level_metrics_behavior = "PER_DATA_SOURCE_METRICS"
    operation_level_metrics_config     = "ENABLED"
  }

  log_config {
    field_log_level          = "NONE"
    cloudwatch_logs_role_arn = local.execution_role_arn
    exclude_verbose_content  = true
  }
}

resource "aws_appsync_domain_name" "default" {
  count           = var.create ? 1 : 0
  domain_name     = "${var.subdomain_name}.${var.domain_name}"
  description     = "create custom domain name for appsync"
  certificate_arn = var.certificate_arn
}

resource "aws_appsync_domain_name_api_association" "this" {
  count       = var.create ? 1 : 0
  api_id      = concat(gravicore_aws_appsync_graphql_api.default.*.id, [""])[0]
  domain_name = aws_appsync_domain_name.default[0].domain_name
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "appsync_merged_api_id" {
  value = var.create ? concat(gravicore_aws_appsync_graphql_api.default.*.id, [""])[0] : ""
}

output "appsync_merged_api_domain_name" {
  value = concat(aws_appsync_domain_name.default.*.appsync_domain_name, [""])[0]
}

output "appsync_merged_api_zone_id" {
  value = concat(aws_appsync_domain_name.default.*.hosted_zone_id, [""])[0]
}
