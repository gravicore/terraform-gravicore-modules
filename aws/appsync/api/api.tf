
# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "graphql" {
  description = "requied. GraphQL schema and resolvers configuration"
  type = object({
    schema = string
    resolvers = optional(list(object({
      field = string
      type  = string
      target = object({
        arn  = optional(string)
        role = optional(string)
        type = optional(string)
      })
      template = object({
        req = optional(string)
        res = optional(string)
      })
    })))
  })
}

variable "authentication" {
  description = "required. Authentication configuration for the AppSync Merged API"
  type = list(object({
    priority = string
    cognito = optional(object({
      user_pool = string
      region    = optional(string)
      regex     = optional(string)
    }), null)
    lambda = optional(object({
      arn   = string
      ttl   = optional(number)
      regex = optional(string)
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
  authentication = [for i, a in var.authentication : merge(
    {
      is_cognito = a.cognito != null
      is_lambda  = a.lambda != null
      priority   = a.priority
    },
    a.cognito == null ? {} : {
      authentication_type = "AMAZON_COGNITO_USER_POOLS"
      regex               = a.cognito.regex != null ? a.cognito.regex : ""
      region              = coalesce(a.cognito.region, var.aws_region)
      user_pool           = a.cognito.user_pool
    },
    a.lambda == null ? {} : {
      arn                 = a.lambda.arn
      authentication_type = "AWS_LAMBDA"
      regex               = coalesce(a.lambda.regex, "(?i)^bearer\\s+(.+)")
      ttl                 = coalesce(a.lambda.ttl, 0)
    },
  )]

  principal = [for a in local.authentication : a if a.priority == "principal"][0]
  secondary = [for a in local.authentication : a if a.priority == "secondary"]
}

resource "aws_appsync_graphql_api" "this" {
  count               = var.create ? 1 : 0
  authentication_type = local.principal.authentication_type
  name                = local.module_prefix
  schema              = var.graphql.schema
  tags                = local.tags

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
      authorizer_result_ttl_in_seconds = local.principal.ttl
      authorizer_uri                   = local.principal.arn
      identity_validation_expression   = local.principal.regex
    }
  }

  dynamic "additional_authentication_provider" {
    for_each = local.secondary
    content {
      authentication_type = additional_authentication_provider.value.authentication_type
      dynamic "user_pool_config" {
        for_each = additional_authentication_provider.value.is_cognito ? [1] : []
        content {
          app_id_client_regex = additional_authentication_provider.value.regex
          aws_region          = coalesce(additional_authentication_provider.value.region, var.aws_region)
          user_pool_id        = additional_authentication_provider.value.user_pool
        }
      }

      dynamic "lambda_authorizer_config" {
        for_each = additional_authentication_provider.value.is_lambda ? [1] : []
        content {
          authorizer_result_ttl_in_seconds = additional_authentication_provider.value.ttl
          authorizer_uri                   = additional_authentication_provider.value.arn
          identity_validation_expression   = additional_authentication_provider.value.regex
        }
      }
    }
  }
}

module "resolvers" {
  count  = var.create ? 1 : 0
  source = "../resolvers"
  appsync = {
    id = concat(aws_appsync_graphql_api.this.*.id, [""])[0]
  }
  resolvers   = var.graphql.resolvers
  name        = var.name
  account_id  = var.account_id
  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "id" {
  description = "The ID of the AppSync API"
  value       = concat(aws_appsync_graphql_api.this.*.id, [""])[0]
}

output "arn" {
  description = "The ARN of the AppSync API"
  value       = concat(aws_appsync_graphql_api.this.*.arn, [""])[0]
}
