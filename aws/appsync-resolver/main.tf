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

module "appsync" {
  count  = var.create ? 1 : 0
  source = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/appsync-merge?ref=0.56.3"

  graphql = {
    schema = var.graphql_schema
    target = {
      lambda = aws_lambda_function.default.arn
      merge  = var.appsync_merged_api_id
    }
    resolvers = [{
      type  = var.resolver_type
      field = var.resolver_field
    }]
  }

  authentication = [{
    priority = "principal"
    lambda = {
      arn   = var.lambda_authorizer_arn
      regex = "(?i)^bearer\\s+(.+)"
    }
  }]

  transform = {
    request = { body = var.request_template }
  }
}

resource "aws_iam_role" "appsync_role" {
  name = "${local.module_prefix}-appsync-role"

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
  name = "${local.module_prefix}-appsync-policy"
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
  source_arn    = [module.appsync.appsync_api_arn.arn]
} 