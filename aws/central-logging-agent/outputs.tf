output "log_group_arn" {
  value       = "${aws_cloudwatch_log_group.default.arn}"
  description = "ARN of the log group"
}

output "vpc_flow_id" {
  value       = "${aws_flow_log.vpc.id}"
  description = "Flow Log IDs of VPCs"
}

output "subnet_flow_ids" {
  value       = "${aws_flow_log.subnets.*.id}"
  description = "Flow Log IDs of subnets"
}

output "eni_flow_ids" {
  value       = "${aws_flow_log.eni.*.id}"
  description = "Flow Log IDs of ENIs"
}
