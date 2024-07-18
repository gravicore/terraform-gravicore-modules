
# # ----------------------------------------------------------------------------------------------------------------------
# # MODULES / RESOURCES
# # ----------------------------------------------------------------------------------------------------------------------


# resource "aws_s3_bucket" "s3_default" {
#   bucket = "${local.module_prefix}-s3-lambda-s3"
# }

# resource "aws_s3_bucket_public_access_block" "s3_default" {
#   bucket = aws_s3_bucket.s3_default.id

#   block_public_acls       = true
#   ignore_public_acls      = true
#   block_public_policy     = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_versioning" "s3_default" {
#   bucket = aws_s3_bucket.s3_default.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }


# resource "aws_s3_object" "s3_default" {
#   depends_on = [data.archive_file.s3_default]

#   bucket      = aws_s3_bucket.s3_default.bucket
#   key         = "${var.s3_lambda_function_name}.zip"
#   source      = "${var.s3_lambda_function_name}.zip"
#   source_hash = data.archive_file.s3_default.output_md5

# }

# data "archive_file" "s3_default" {
#   type        = "zip"
#   output_path = "${var.s3_lambda_function_name}.zip"
#   source_file = var.s3_file_name
# }
