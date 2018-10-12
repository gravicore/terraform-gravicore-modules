output "log_bucket_name" {
  value       = "${module.log_storage.bucket_id}"
  description = "Name of the logging bucket"
}

output "logging-lambda" {
  value       = "${aws_cloudformation_stack.aws_central_logging_lambda.outputs["Function"]}"
  description = "ARN of the central logging lambda"
}

output "vpc_flow_id" {
  value       = "${aws_flow_log.vpc.id}"
  description = "Flow Log IDs of VPCs"
}
