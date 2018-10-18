output "flow_log_group_arn" {
  value       = "${module.flow_log_destination.flow_log_group_arn}"
  description = "ARN of the log group"
}

output "flow_log_group_name" {
  value       = "${module.flow_log_destination.log_group_name}"
  description = "ARN of the log group"
}

output "log_group_iam_role_arn" {
  value       = "${aws_iam_role.log.arn}"
  description = "ARN of the log group"
}
