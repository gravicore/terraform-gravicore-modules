output "log_group_arn" {
  value       = "${aws_cloudwatch_log_group.default.arn}"
  description = "ARN of the log group"
}

output "log_group_name" {
  value       = "${aws_cloudwatch_log_group.default.name}"
  description = "ARN of the log group"
}
