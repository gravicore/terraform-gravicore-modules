
# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "graphql" {
  type = object({
    schema = string
    target = object({
      lambda = string
      merge  = string
    })
    authentication = object({
      type      = optional(string, "AMAZON_COGNITO_USER_POOLS")
      user_pool = string
    })
    resolvers = optional(list(object({
      field = string
      type  = string
    })), [])
  })
  description = "required. The GraphQL schema and resolvers configuration"
}

variable "transform" {
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
  default     = {}
  description = "optional. The request and response transformation configuration"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
locals {
  req          = var.transform.request
  res          = var.transform.response
  req_template = local.req.body != "" ? local.req.body : file("${path.module}/transform/req/${local.req.type}.vtl")
  res_template = local.res.body != "" ? local.res.body : file("${path.module}/transform/res/${local.res.type}.vtl")
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
  authentication_type = var.graphql.authentication.type
  name                = local.module_prefix
  schema              = var.graphql.schema
  tags                = local.tags

  user_pool_config {
    aws_region     = var.aws_region
    default_action = "ALLOW"
    user_pool_id   = var.graphql.authentication.user_pool
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

resource "gravicore_aws_appsync_start_schema_merge" "this" {
  count          = var.create ? 1 : 0
  association_id = concat(gravicore_aws_appsync_merged_api_association.this.*.id, [""])[0]
  merged_api_id  = var.graphql.target.merge
  lifecycle {
    replace_triggered_by = [
      aws_appsync_graphql_api.this,
      gravicore_aws_appsync_merged_api_association.this,
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
