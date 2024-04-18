
# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------



variable "graphql_schema" {
  type        = string
  description = "Description of the Lambda function"
}


variable "graphql_authentication_type" {
  type        = string
  description = "Description of the Lambda function"
}




# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_appsync_datasource" "default" {
  api_id           = aws_appsync_graphql_api.default.id
  name             = "lambda_appsync_datasource"
  service_role_arn = aws_iam_role.appsync_service_role.arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = aws_lambda_function.default.arn
  }
}

resource "aws_appsync_graphql_api" "default" {
  authentication_type = var.graphql_authentication_type
  visibility          = "PRIVATE"
  name                = "${local.module_prefix}-appsync-api-lambda"
  schema              = var.graphql_schema
}
