module "log_storage" {
  source    = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=0.2.2"
  name      = "${var.name}"
  namespace = "${local.environment_prefix}"
  stage     = "${var.stage}"
}

resource "aws_cloudformation_stack" "aws_central_logging_lambda" {
  name          = "${local.module_prefix}-lambda"
  capabilities  = ["CAPABILITY_IAM"]
  template_body = "${file("${path.module}/cloudformation/aws-central-logging-lambda.cft")}"
}

module "central_logging_agent" {
  source = "./agent"

  namespace         = "${var.namespace}"
  environment       = "${var.environment}"
  stage             = "${var.stage}"
  master_account_id = "${var.master_account_id}"
  repository        = "${var.repository}"
  account_id        = "${var.account_id}"
}
