# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------


variable "s3_lambda_function_description" {
  type        = string
  description = "Description of the Lambda function"
}

variable "s3_lambda_function_handler" {
  type        = string
  description = "Name of the Lambda function handler ex: main.handler"
}

variable "s3_lambda_function_runtime" {
  type        = string
  description = "Runtime of the Lambda function ex: python3.8"
}


variable "s3_lambda_function_memory_size" {
  type        = number
  description = "Memory size of the Lambda function ex: 128"
}

variable "s3_lambda_function_timeout" {
  type        = number
  description = "Function timeout of the Lambda function ex: 3"
}


variable "s3_lambda_environment_variables" {
  default     = {}
  type        = map(string)
  description = "Map of environment variables for the Lambda function"
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------



resource "aws_lambda_function" "s3_default" {
  count         = var.create ? 1 : 0
  depends_on    = [aws_s3_object.s3_default]
  description   = var.s3_lambda_function_description
  s3_bucket     = data.aws_s3_bucket.s3_default[0].bucket
  s3_key        = "${var.name}.zip"
  function_name = local.module_prefix
  role          = aws_iam_role.s3_default[0].arn
  handler       = var.s3_lambda_function_handler
  runtime       = var.s3_lambda_function_runtime
  memory_size   = var.s3_lambda_function_memory_size
  timeout       = var.s3_lambda_function_timeout

  source_code_hash = data.archive_file.s3_default[0].output_md5

  environment {
    variables = merge(
      { for k, v in local.tags : lower(join("", regexall("[a-zA-Z0-9_]+", k))) => v },
      var.s3_lambda_environment_variables,
      { "SQS_URL" = aws_sqs_queue.default[0].url }
    )
  }
  # vpc_config {
  #   subnet_ids         = var.vpc_subnet_ids
  #   security_group_ids = var.vpc_security_group_ids
  # }
}



# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "s3_lambda_lambda_arn" {
  description = "ARN of the Lambda function"
  value       = coalesce(join("", aws_lambda_function.s3_default[*].arn), "")
}