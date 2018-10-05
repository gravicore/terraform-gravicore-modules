# resource "aws_cloudformation_stack" "aws_central_log_bucket" {
#   name         = "aws-central-log-bucket"
#   capabilities = ["CAPABILITY_IAM"]

#   parameters {
#     BucketName = "msn-central-logging-bucket"
#   }

#   template_body = "${file("../terraform-central-logging/cloudformation/aws-central-log-bucket.cft")}"
# }

module "log_storage" {
  source    = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=master"
  name      = "${var.name}"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
}

resource "aws_cloudformation_stack" "aws_central_logging_lambda" {
  name          = "${var.name}-lambda"
  capabilities  = ["CAPABILITY_IAM"]
  template_body = "${file("${path.module}/cloudformation/aws-central-logging-lambda.cft")}"
}

resource "aws_cloudformation_stack" "aws_central_logging_destination" {
  depends_on = [
    "module.log_storage",
    "aws_cloudformation_stack.aws_central_logging_lambda",
  ]

  count = "${length(keys(var.child_account))}"

  name         = "${var.name}-${element(keys(var.child_account), count.index)}"
  capabilities = ["CAPABILITY_IAM"]

  parameters {
    # LogBucketName       = "${aws_cloudformation_stack.aws_central_log_bucket.outputs["CentralLogBucket"]}"
    LogBucketName       = "${module.log_storage.bucket_id}"
    LogS3Location       = "${var.s3_log_Location}/${element(values(var.child_account), count.index)}/${var.stage}/"
    ProcessingLambdaARN = "${aws_cloudformation_stack.aws_central_logging_lambda.outputs["Function"]}"
    SourceAccount       = "${element(keys(var.child_account), count.index)}"
  }

  template_body = "${file("${path.module}/cloudformation/aws-central-logging-destination.cft")}"
}

# resource "aws_cloudformation_stack" "aws_central_logging_destination2" {
#   depends_on = [
#     "module.log_storage",
#     "aws_cloudformation_stack.aws_central_logging_lambda",
#   ]


#   name         = "${var.name}-552324202284"
#   capabilities = ["CAPABILITY_IAM"]


#   parameters {
#     # LogBucketName       = "${aws_cloudformation_stack.aws_central_log_bucket.outputs["CentralLogBucket"]}"
#     LogBucketName       = "${module.log_storage.bucket_id}"
#     LogS3Location       = "log/test/"
#     ProcessingLambdaARN = "${aws_cloudformation_stack.aws_central_logging_lambda.outputs["Function"]}"
#     SourceAccount       = "552324202284"
#   }


#   template_body = "${file("${path.module}/cloudformation/aws-central-logging-destination.cft")}"
# }

