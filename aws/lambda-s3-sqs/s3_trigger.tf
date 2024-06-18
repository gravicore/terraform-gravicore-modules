# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------


variable "trigger_s3_lambda_bucket_id" {
  type        = string
  description = "S3 bucket that will trigger the Lambda function"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_notification" "default" {
  bucket = var.trigger_s3_lambda_bucket_id
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_default.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]

  }
}
resource "aws_lambda_permission" "s3_default" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_default.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.trigger_s3_lambda_bucket_id}"
}
