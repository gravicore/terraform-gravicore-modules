
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


resource "aws_appsync_graphql_api" "example" {
  authentication_type = "var.graphql_authentication_type"
  name                = "${var.module_prefix}-appsync-api"
  schema              = var.graphql_schema
}
