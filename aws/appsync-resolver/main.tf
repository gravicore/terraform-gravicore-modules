terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# LOCALS
# ----------------------------------------------------------------------------------------------------------------------

locals {
  module_prefix = "${var.namespace}-${var.environment}-${var.stage}-${var.name}"
}

# ----------------------------------------------------------------------------------------------------------------------
# LAMBDA RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_lambda_function" "default" {
  filename      = data.archive_file.default.output_path
  function_name = local.module_prefix
  role          = var.lambda_role_arn
  handler       = var.handler

  source_code_hash = filebase64sha256(data.archive_file.default.output_path)

  runtime     = var.lambda_runtime
  timeout     = var.timeout
  memory_size = var.memory_size
  layers      = var.lambda_layers

  reserved_concurrent_executions = var.reserved_concurrency

  vpc_config {
    subnet_ids         = var.vpc_private_subnets
    security_group_ids = var.vpc_security_group_ids
  }

  environment {
    variables = var.environmental_variables
  }
  tags = var.tags

  tracing_config {
    mode = "Active"
  }
  publish = var.provisioned_concurreny >= 1 ? true : null
}

resource "aws_lambda_provisioned_concurrency_config" "default" {
  count                             = var.provisioned_concurreny >= 1 ? 1 : 0
  function_name                     = aws_lambda_function.default.function_name
  provisioned_concurrent_executions = var.provisioned_concurreny
  qualifier                         = aws_lambda_function.default.version
}

data "archive_file" "default" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = var.output_path
}

# ----------------------------------------------------------------------------------------------------------------------
# APPSYNC RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_appsync_graphql_api" "api" {
  count = var.appsync_merged_api_id == "" ? 1 : 0

  name                = var.name
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  schema             = var.graphql_schema
}

resource "aws_appsync_resolver" "resolver" {
  api_id      = var.appsync_merged_api_id != "" ? var.appsync_merged_api_id : aws_appsync_graphql_api.api[0].id
  type        = var.resolver_type
  field       = var.resolver_field
  data_source = aws_appsync_datasource.lambda.name

  request_template = var.request_template

  response_template = <<-EOF
    #if($ctx.error)
      $utils.error($ctx.error.message, $ctx.error.type)
    #end
    #if($ctx.result)
      $utils.toJson($ctx.result)
    #else
      null
    #end
  EOF
}

resource "aws_appsync_datasource" "lambda" {
  api_id           = var.appsync_merged_api_id != "" ? var.appsync_merged_api_id : aws_appsync_graphql_api.api[0].id
  name             = "${var.name}-datasource"
  service_role_arn = aws_iam_role.appsync_role.arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = aws_lambda_function.default.arn
  }
}

resource "aws_iam_role" "appsync_role" {
  name = "${var.name}-appsync-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "appsync.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "appsync_policy" {
  name = "${var.name}-appsync-policy"
  role = aws_iam_role.appsync_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.default.arn
        ]
      }
    ]
  })
}

resource "aws_lambda_permission" "appsync" {
  statement_id  = "AllowExecutionFromAppsync"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.default.function_name
  principal     = "appsync.amazonaws.com"
  source_arn    = aws_appsync_graphql_api.api[0].arn
} 