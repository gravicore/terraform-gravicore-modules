resource "aws_cloudformation_stack" "aws_central_logging_destination" {
  count        = "${var.enabled == "true" ? 1 : 0}"
  provider     = "aws.master"
  name         = "${local.name_prefix}-${var.account_id}"
  capabilities = ["CAPABILITY_IAM"]

  parameters {
    LogBucketName       = "${data.terraform_remote_state.master_acct.log_bucket_name}"
    LogS3Location       = "${var.account_id}/${var.log_type}"
    ProcessingLambdaARN = "${data.terraform_remote_state.master_acct.central_logging_lambda}"
    SourceAccount       = "${var.account_id}"
  }

  template_body = "${file("${path.module}/cloudformation/aws-central-logging-destination.cft")}"
}
