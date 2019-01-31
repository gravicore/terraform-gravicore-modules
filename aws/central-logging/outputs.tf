output "log_bucket_name" {
  value       = "${module.log_storage.bucket_id}"
  description = "Name of the logging bucket"
}

output "central_logging_lambda" {
  value       = "${aws_cloudformation_stack.aws_central_logging_lambda.outputs["Function"]}"
  description = "ARN of the central logging lambda"
}

output "flow_log_group_name" {
  value       = "${module.central_logging_agent.flow_log_group_name}"
  description = "ARN of the log group"
}

output "log_group_iam_role_arn" {
  value       = "${module.central_logging_agent.log_group_iam_role_arn}"
  description = "ARN of the log group"
}

output "log_group_iam_role_unique_id" {
  value       = "${module.central_logging_agent.log_group_iam_role_unique_id}"
  description = "The stable and unique string identifying the role"
}

output "log_group_iam_role_name" {
  value       = "${module.central_logging_agent.log_group_iam_role_name}"
  description = "The name of the role."
}

output "flow_log_group_arn" {
  value       = "${module.central_logging_agent.flow_log_group_arn}"
  description = "The flow log log group's Amazon Resource Name (ARN) specifying the log group"
}

output "flow_log_destination_arn" {
  value       = "${module.central_logging_agent.flow_log_destination_arn}"
  description = "The kinesis destination's Amazon Resource Name (ARN) specifying the log group"
}
