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

# Lookup the existing S3 bucket by name
data "aws_s3_bucket" "s3_default" {
  count  = var.create ? 1 : 0
  bucket = local.module_prefix
}

resource "aws_s3_object" "s3_default" {
  count       = var.create ? 1 : 0
  depends_on  = [data.archive_file.s3_default]
  bucket      = coalesce(join("", data.aws_s3_bucket.s3_default[*].bucket), "")
  key         = "${var.name}.zip"
  source      = "../../../python/${var.name}.zip"
  source_hash = coalesce(join("", data.archive_file.s3_default[*].output_md5), "")
}

data "archive_file" "s3_default" {
  count       = var.create ? 1 : 0
  type        = "zip"
  output_path = "../../../python/${var.name}.zip"
  source_dir  = "../../../python/${var.name}"
}
