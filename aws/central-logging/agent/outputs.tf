output "flow_log_group_name" {
  value       = "${module.flow_log_destination.log_group_name}"
  description = "Name of the flow log log group"
}

output "log_group_iam_role_arn" {
  value       = "${aws_iam_role.log.arn}"
  description = "The Amazon Resource Name (ARN) specifying the role"
}

output "log_group_iam_role_unique_id" {
  value       = "${aws_iam_role.log.unique_id}"
  description = "The stable and unique string identifying the role"
}

output "log_group_iam_role_name" {
  value       = "${aws_iam_role.log.name}"
  description = "The name of the role."
}

output "flow_log_group_arn" {
  value       = "${module.flow_log_destination.log_group_arn}"
  description = "The flow log log group's Amazon Resource Name (ARN) specifying the log group"
}

output "flow_log_destination_arn" {
  value       = "${module.flow_log_destination.destination_arn}"
  description = "The kinesis destination's Amazon Resource Name (ARN) specifying the log group"
}
