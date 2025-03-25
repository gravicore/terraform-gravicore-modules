variable "name" {
  type        = string
  description = "Name of the AppSync resolver"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "namespace" {
  type        = string
  description = "Namespace for the resource"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "stage" {
  type        = string
  description = "Stage name"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
}

variable "appsync_merged_api_id" {
  type        = string
  description = "The AppSync Merged API ID to connect to the AppSync API"
}

variable "graphql_schema" {
  type        = string
  description = "GraphQL schema definition"
}

variable "lambda_authorizer_arn" {
  type        = string
  description = "The ARN of the Lambda Authorizer"
}

variable "lambda_function_arn" {
  type        = string
  description = "The ARN of the Lambda function to invoke"
}

variable "resolver_type" {
  type        = string
  description = "Type of resolver (Query or Mutation)"
}

variable "resolver_field" {
  type        = string
  description = "Field name for the resolver"
}

variable "request_template" {
  type        = string
  description = "VTL template for request transformation"
}

# Lambda variables
variable "lambda_role_arn" {
  type        = string
  description = "ARN of the IAM role for Lambda execution"
}

variable "lambda_layers" {
  type        = list(string)
  description = "List of Lambda layer ARNs"
  default     = []
}

variable "vpc_private_subnets" {
  type        = list(string)
  description = "List of VPC private subnet IDs"
  default     = []
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "List of VPC security group IDs"
  default     = []
}

variable "lambda_runtime" {
  type        = string
  description = "Lambda runtime"
  default     = "python3.9"
}

variable "file_name" {
  type        = string
  description = "Name of the Lambda function file"
}

variable "timeout" {
  type        = number
  description = "Lambda function timeout in seconds"
  default     = 60
}

variable "memory_size" {
  type        = number
  description = "Lambda function memory size in MB"
  default     = 128
}

variable "handler" {
  type        = string
  description = "Lambda function handler"
}

variable "environmental_variables" {
  type        = map(any)
  description = "Environment variables for Lambda function"
  default     = {}
}

variable "reserved_concurrency" {
  type        = number
  description = "Reserved concurrency for Lambda function"
  default     = -1
}

variable "provisioned_concurreny" {
  type        = number
  description = "Provisioned concurrency for Lambda function"
  default     = 0
}

variable "source_dir" {
  type        = string
  description = "Source directory for Lambda function code"
}

variable "output_path" {
  type        = string
  description = "Output path for Lambda function zip file"
} 