# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------


variable "function_folder" {
  type        = string
  description = "Folder path to the Lambda function source code"
}


variable "function_entrypoint" {
  type        = string
  description = "File path to the Lambda function entrypoint (app.py, main.js, etc.)"
}



# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------


resource "aws_s3_bucket" "default" {
  bucket = "${local.module_prefix}-lambda"
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.default.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "default" {
  bucket = aws_s3_bucket.default.id

  versioning_configuration {
    status = "Enabled"
  }
}


##### ------ S3 Object for ECR Scan Trigger Lambda ------ #####

resource "aws_s3_object" "default" {
  depends_on = [data.archive_file.default]

  bucket      = aws_s3_bucket.default.bucket
  key         = "${var.function_name}.zip"
  source      = "${path.module}/${var.function_folder}/${var.function_name}.zip"
  source_hash = data.archive_file.default.output_md5
}

data "archive_file" "default" {
  type        = "zip"
  output_path = "${path.module}/${var.function_folder}/${var.function_name}.zip"
  source_file = "${path.module}/${var.function_folder}/${var.function_entrypoint}"
}
