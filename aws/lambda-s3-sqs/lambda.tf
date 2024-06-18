# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------


variable "function_description" {
  type        = string
  description = "Description of the Lambda function"
}

variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "function_handler" {
  type        = string
  description = "Name of the Lambda function handler ex: main.handler"
}

variable "function_runtime" {
  type        = string
  description = "Runtime of the Lambda function ex: python3.8"
}


variable "function_memory_size" {
  type        = number
  description = "Memory size of the Lambda function ex: 128"
}

variable "function_timeout" {
  type        = number
  description = "Function timeout of the Lambda function ex: 3"
}


# variable "environment_variables" {
#   type        = map(string)
#   description = "Map of environment variables for the Lambda function"
# }


# variable "vpc_subnet_ids" {
#   type        = list(string)
#   description = "List of VPC subnet IDs to connect the Lambda function to"
# }

# variable "vpc_security_group_ids" {
#   type        = list(string)
#   description = "List of VPC security group IDs to connect the Lambda function to"
# }

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------



resource "aws_lambda_function" "default" {
  depends_on    = [aws_s3_object.default]
  description   = var.function_description
  s3_bucket     = aws_s3_bucket.default.bucket
  s3_key        = "${var.function_name}.zip"
  function_name = var.function_name
  role          = aws_iam_role.default.arn
  handler       = var.function_handler
  runtime       = var.function_runtime
  memory_size   = var.function_memory_size
  timeout       = var.function_timeout

  source_code_hash = data.archive_file.default.output_base64sha256

  # environment {
  #   variables = var.environment_variables
  # }
  # vpc_config {
  #   subnet_ids         = var.vpc_subnet_ids
  #   security_group_ids = var.vpc_security_group_ids
  # }
}



# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "lambda_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.default.arn
}
