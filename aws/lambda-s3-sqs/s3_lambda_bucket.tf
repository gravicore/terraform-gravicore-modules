# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------


variable "s3_lambda_function_folder" {
  type        = string
  description = "Folder path to the Lambda function source code"
}


variable "s3_lambda_function_entrypoint" {
  type        = string
  description = "File path to the Lambda function entrypoint (app.py, main.js, etc.)"
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------


resource "aws_s3_bucket" "s3_default" {
  bucket = "${local.module_prefix}-s3-lambda"
}

resource "aws_s3_bucket_public_access_block" "s3_default" {
  bucket = aws_s3_bucket.s3_default.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "s3_default" {
  bucket = aws_s3_bucket.s3_default.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_object" "s3_default" {
  depends_on = [data.archive_file.s3_default]

  bucket      = aws_s3_bucket.s3_default.bucket
  key         = "${var.s3_lambda_function_name}.zip"
  source      = "${path.module}/${var.s3_lambda_function_folder}/${var.function_name}.zip"
  source_hash = data.archive_file.default.output_md5
}

data "archive_file" "default" {
  type        = "zip"
  output_path = "${path.module}/${var.s3_lambda_function_folder}/${var.s3_lambda_function_name}.zip"
  source_file = "${path.module}/${var.s3_lambda_function_folder}/${var.s3_lambda_function_entrypoint}"
}
