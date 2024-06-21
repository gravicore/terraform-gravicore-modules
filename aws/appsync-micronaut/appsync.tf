
# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "appsync_merged_api_id" {
  type        = string
  description = "The AppSync Merged API ID to connect to the AppSync API"
}

variable "graphql_schema" {
  type        = string
  description = "Description of the Lambda function"
}

variable "graphql_authentication_type" {
  type        = string
  description = "Description of the Lambda function"
}

variable "lambda_function_arn" {
  type        = string
  description = "ARN of the Lambda function to connect to the AppSync API"
}

variable "cognito_user_pool" {
  type        = string
  description = "User Pool ID for the AppSync API"
}

variable "resolver_field_name" {
  type        = string
  description = "The field name to attach the resolver to"
}

variable "resolver_type_name" {
  type        = string
  description = "The type name to attach the resolver to"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

locals {
  environment = {
    AWS_REGION            = var.aws_region
    AWS_ACCOUNT_ID        = var.account_id
    APPSYNC_MERGED_API_ID = var.appsync_merged_api_id
  }
}

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

  user_pool_config {
    aws_region     = var.aws_region
    default_action = "ALLOW"
    user_pool_id   = var.cognito_user_pool
  }

  # workaround to access values in destroy
  tags = local.environment
  provisioner "local-exec" {
    when = create
    environment = merge(self.tags, {
      APPSYNC_API_ID = self.id
    })
    command = <<EOF
      pip install --force-reinstall -qq boto3 && \
      python ${path.module}/bin/create.py
EOF
  }

  # https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax#destroy-time-provisioners
  provisioner "local-exec" {
    when = destroy
    environment = merge(self.tags, {
      APPSYNC_API_ID = self.id
    })
    command = <<EOF
      pip install --force-reinstall -qq boto3 && \
      python ${path.module}/bin/destroy.py
EOF
  }
}

resource "aws_appsync_resolver" "this" {
  count = var.create ? 1 : 0

  api_id      = aws_appsync_graphql_api.this[0].id
  type        = var.resolver_type_name
  field       = var.resolver_field_name
  data_source = aws_appsync_datasource.this[0].name

  request_template  = file("${path.module}/templates/request.vtl")
  response_template = file("${path.module}/templates/response.vtl")
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "appsync_api_id" {
  description = "The ID of the AppSync GraphQL API"
  value       = concat(aws_appsync_graphql_api.this.*.id, [""])[0]
}
