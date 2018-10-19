output "log_group_name" {
  value       = "${aws_cloudwatch_log_group.default.name}"
  description = "ARN of the log group"
}

output "log_group_arn" {
  value       = "${aws_cloudwatch_log_group.default.arn}"
  description = "The log group's Amazon Resource Name (ARN) specifying the log group"
}

output "destination_arn" {
  value       = "${aws_cloudformation_stack.aws_central_logging_destination.outputs["Destination"]}"
  description = "The kinesis destination's Amazon Resource Name (ARN) specifying the log group"
}
