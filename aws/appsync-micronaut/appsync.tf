
# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "appsync_merged_api_id" {
  type        = string
  description = "The AppSync Merged API ID to connect the AppSync API"
}

variable "graphql_schema" {
  type        = string
  description = "The schema for the AppSync API"
}

variable "graphql_authentication_type" {
  type        = string
  description = "The authentication type for the AppSync API"
}

variable "lambda_function_arn" {
  type        = string
  description = "ARN of the Lambda function to connect AppSync"
}

variable "cognito_user_pool" {
  type        = string
  description = "User Pool ID for the AppSync API"
}

variable "resolver_field_name" {
  type        = list(string)
  description = "The field name to attach the resolver to"
}

variable "resolver_type_name" {
  type        = list(string)
  description = "The type name to attach the resolver to"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_appsync_datasource" "this" {
  count            = var.create ? 1 : 0
  api_id           = aws_appsync_graphql_api.this[0].id
  name             = lower(join("", regexall("[a-zA-Z0-9]+", local.module_prefix)))
  service_role_arn = aws_iam_role.this[0].arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = var.lambda_function_arn
  }
}

resource "aws_appsync_graphql_api" "this" {
  count               = var.create ? 1 : 0
  authentication_type = var.graphql_authentication_type
  name                = local.module_prefix
  schema              = var.graphql_schema
  tags                = local.tags

  user_pool_config {
    aws_region     = var.aws_region
    default_action = "ALLOW"
    user_pool_id   = var.cognito_user_pool
  }
}

resource "aws_appsync_resolver" "this" {
  count             = var.create ? length(var.resolver_field_name) : 0
  api_id            = aws_appsync_graphql_api.this[0].id
  type              = var.resolver_type_name[count.index]
  field             = var.resolver_field_name[count.index]
  data_source       = aws_appsync_datasource.this[0].name
  request_template  = file("${path.module}/request.vtl")
  response_template = file("${path.module}/response.vtl")
}

resource "asm_appsync_merged_api_association" "this" {
  count         = var.create ? 1 : 0
  description   = "${local.module_prefix} association"
  merged_api_id = var.appsync_merged_api_id
  source_api_id = aws_appsync_graphql_api.this[0].id
  source_api_association_config {
    merge_type = "MANUAL_MERGE"
  }
}

resource "asm_appsync_start_schema_merge" "this" {
  count          = var.create ? 1 : 0
  association_id = asm_appsync_merged_api_association.this[0].id
  merged_api_id  = var.appsync_merged_api_id
  lifecycle {
    replace_triggered_by = [
      aws_appsync_graphql_api.this,
      asm_appsync_merged_api_association.this,
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
