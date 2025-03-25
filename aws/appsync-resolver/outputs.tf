# AppSync outputs
output "api_id" {
  description = "The ID of the AppSync API"
  value       = var.appsync_merged_api_id != "" ? var.appsync_merged_api_id : aws_appsync_graphql_api.api[0].id
}

output "resolver_arn" {
  description = "The ARN of the AppSync resolver"
  value       = aws_appsync_resolver.resolver.arn
}

output "datasource_name" {
  description = "The name of the AppSync datasource"
  value       = aws_appsync_datasource.lambda.name
}

output "appsync_role_arn" {
  description = "The ARN of the AppSync IAM role"
  value       = aws_iam_role.appsync_role.arn
}

# Lambda outputs
output "lambda_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.default.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.default.function_name
}

output "lambda_invoke_arn" {
  description = "The invocation ARN of the Lambda function"
  value       = aws_lambda_function.default.invoke_arn
} 