
# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "graphql" {
  description = "required. GraphQL schema and resolvers configuration"
  type = object({
    schema = string
    target = object({
      lambda = string
      merge  = string
    })
    resolvers = optional(list(object({
      field = string
      type  = string
    })), [])
  })
}

variable "transform" {
  description = "optional. Request and response transformation configuration"
  type = object({
    request = optional(object({
      type = optional(string, "default")
      body = optional(string, "")
    }), {})
    response = optional(object({
      type = optional(string, "default")
      body = optional(string, "")
    }), {})
  })
  default = {}
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
  req = var.transform.request
  res = var.transform.response

  req_template = local.req.body != "" ? local.req.body : file("${path.module}/transform/req/${local.req.type}.vtl")
  res_template = local.res.body != "" ? local.res.body : file("${path.module}/transform/res/${local.res.type}.vtl")

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

resource "aws_appsync_datasource" "this" {
  count            = var.create ? 1 : 0
  api_id           = concat(aws_appsync_graphql_api.this.*.id, [""])[0]
  name             = lower(join("", regexall("[a-zA-Z0-9]+", local.module_prefix)))
  service_role_arn = concat(aws_iam_role.this.*.arn, [""])[0]
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = var.graphql.target.lambda
  }
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

resource "aws_appsync_resolver" "this" {
  count             = var.create ? length(var.graphql.resolvers) : 0
  api_id            = concat(aws_appsync_graphql_api.this.*.id, [""])[0]
  data_source       = concat(aws_appsync_datasource.this.*.name, [""])[0]
  field             = var.graphql.resolvers[count.index].field
  request_template  = local.req_template
  response_template = local.res_template
  type              = var.graphql.resolvers[count.index].type
}

resource "gravicore_aws_appsync_merged_api_association" "this" {
  count         = var.create ? 1 : 0
  description   = "${local.module_prefix} association"
  merged_api_id = var.graphql.target.merge
  source_api_id = concat(aws_appsync_graphql_api.this.*.id, [""])[0]
  source_api_association_config {
    merge_type = "MANUAL_MERGE"
  }
}

resource "null_resource" "this" {
  triggers = {
    timestamp = timestamp()
  }
}

resource "gravicore_aws_appsync_start_schema_merge" "this" {
  count           = var.create ? 1 : 0
  association_id  = try(split("_", concat(gravicore_aws_appsync_merged_api_association.this.*.id, [""])[0])[1], "")
  merged_api_id   = var.graphql.target.merge
  timeout_seconds = 60
  lifecycle {
    replace_triggered_by = [
      null_resource.this,
    ]
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "appsync_api_id" {
  description = "The ID of the AppSync GraphQL API"
  value       = concat(aws_appsync_graphql_api.this.*.id, [""])[0]
}

output "appsync_api_arn" {
  description = "The ID of the AppSync GraphQL API"
  value       = concat(aws_appsync_graphql_api.this.*.arn, [""])[0]
}
