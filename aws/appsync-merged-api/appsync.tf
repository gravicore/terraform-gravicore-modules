# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "domain" {
  description = "required. Domain configuration for the AppSync Merged API"
  type = object({
    zone = string
    name = string
    cert = string
  })
}

variable "authentication" {
  description = "required. Authentication configuration for the AppSync Merged API"
  type = list(object({
    priority = string # principal or secondary
    cognito = optional(object({
      user_pool = string
      region    = optional(string, "")
      regex     = optional(string, "")
    }), null)
    lambda = optional(object({
      arn   = string
      ttl   = optional(number, 0)
      regex = optional(string, "")
    }), null)
  }))
  validation {
    condition = alltrue([
      for auth in var.authentication : (
        (auth.cognito != null && auth.lambda == null) ||
        (auth.cognito == null && auth.lambda != null)
      )
      ]) && alltrue([
      for auth in var.authentication : (
        auth.priority == "principal" || auth.priority == "secondary"
      )
    ])
    error_message = "Each authentication object must have either 'cognito' or 'lambda' defined, but not both, and 'priority' must be either 'principal' or 'secondary'."
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

locals {
  authentication_types = {
    cognito = "AMAZON_COGNITO_USER_POOLS"
    lambda  = "AWS_LAMBDA"
  }

  authentication = [for i, a in var.authentication : merge(
    coalesce(a.cognito, a.lambda),
    {
      authentication_type = local.authentication_types[[for k in keys(a) : k if a[k] != null][0]]
      is_cognito          = a.cognito != null
      is_lambda           = a.lambda != null
      priority            = a.priority
  })]

  principal = [for a in local.authentication : a if a.priority == "principal"][0]
  secondary = [for a in local.authentication : a if a.priority == "secondary"]
}

resource "aws_iam_role" "this" {
  count = var.create ? 1 : 0
  name  = local.module_prefix

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "appsync.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "this" {
  count  = var.create ? 1 : 0
  name   = local.module_prefix
  policy = concat(data.aws_iam_policy_document.this.*.json, [""])[0]
  role   = concat(aws_iam_role.this.*.id, [""])[0]
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
  count                         = var.create ? 1 : 0
  api_type                      = "MERGED"
  authentication_type           = local.principal.authentication_type
  merged_api_execution_role_arn = concat(aws_iam_role.this.*.arn, [""])[0]
  name                          = local.module_prefix
  tags                          = var.tags
  xray_enabled                  = true

  dynamic "user_pool_config" {
    for_each = local.principal.is_cognito ? [1] : []
    content {
      app_id_client_regex = local.principal.regex
      aws_region          = coalesce(local.principal.region, var.aws_region)
      default_action      = "ALLOW"
      user_pool_id        = local.principal.user_pool
    }
  }

  dynamic "lambda_authorizer_config" {
    for_each = local.principal.is_lambda ? [1] : []
    content {
      authorizer_result_ttl_seconds  = local.principal.ttl
      authorizer_uri                 = local.principal.arn
      identity_validation_expression = local.principal.regex
    }
  }

  enhanced_metrics_config {
    data_source_level_metrics_behavior = "PER_DATA_SOURCE_METRICS"
    operation_level_metrics_config     = "ENABLED"
    resolver_level_metrics_behavior    = "PER_RESOLVER_METRICS"
  }

  log_config {
    cloudwatch_logs_role_arn = concat(aws_iam_role.this.*.arn, [""])[0]
    exclude_verbose_content  = true
    field_log_level          = "NONE"
  }

  dynamic "additional_authentication_providers" {
    for_each = local.secondary
    content {
      authentication_type = additional_authentication_providers.value.authentication_type
      dynamic "user_pool_config" {
        for_each = additional_authentication_providers.value.is_cognito ? [1] : []
        content {
          app_id_client_regex = additional_authentication_providers.value.regex
          aws_region          = coalesce(additional_authentication_providers.value.region, var.aws_region)
          user_pool_id        = additional_authentication_providers.value.user_pool
        }
      }

      dynamic "lambda_authorizer_config" {
        for_each = additional_authentication_providers.value.is_lambda ? [1] : []
        content {
          authorizer_result_ttl_seconds  = additional_authentication_providers.value.ttl
          authorizer_uri                 = additional_authentication_providers.value.arn
          identity_validation_expression = additional_authentication_providers.value.regex
        }
      }
    }
  }
}

resource "aws_appsync_domain_name" "default" {
  count           = var.create ? 1 : 0
  domain_name     = "${var.domain.name}.${var.domain.zone}"
  description     = "create custom domain name for appsync"
  certificate_arn = var.domain.cert
}

resource "aws_appsync_domain_name_api_association" "this" {
  count       = var.create ? 1 : 0
  api_id      = concat(gravicore_aws_appsync_graphql_api.default.*.id, [""])[0]
  domain_name = concat(aws_appsync_domain_name.default.*.domain_name, [""])[0]
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
