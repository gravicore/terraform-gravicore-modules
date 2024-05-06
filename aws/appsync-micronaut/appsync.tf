
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

variable "datasource_name" {
  type        = string
  description = "Datasource name for the AppSync API"
}

variable "lambda_function_arn" {
  type        = string
  description = "ARN of the Lambda function to connect to the AppSync API"
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_appsync_datasource" "default" {
  api_id           = aws_appsync_graphql_api.default.id
  name             = var.datasource_name
  service_role_arn = aws_iam_role.appsync_service_role.arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = var.lambda_function_arn
  }
}

resource "aws_appsync_graphql_api" "default" {
  authentication_type = var.graphql_authentication_type
  name                = "${var.datasource_name}-appsync-api"
  schema              = var.graphql_schema
}
