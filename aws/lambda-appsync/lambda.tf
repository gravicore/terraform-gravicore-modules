# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------


variable "function_description" {
  type        = string
  description = "Description of the Lambda function"
}

variable "function_name" {
  type        = string
  description = "(optional) describe your variable"
}

variable "function_handler" {
  type        = string
  description = "(optional) describe your variable"
}

variable "function_runtime" {
  type        = string
  description = "(optional) describe your variable"
}


variable "function_memory_size" {
  type        = number
  description = "(optional) describe your variable"
}

variable "function_timeout" {
  type        = number
  description = "(optional) describe your variable"
}


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

}



# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------


