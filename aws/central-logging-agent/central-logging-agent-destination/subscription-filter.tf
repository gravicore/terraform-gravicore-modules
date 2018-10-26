resource "aws_cloudwatch_log_subscription_filter" "default" {
  count           = "${var.enabled == "true" ? 1 : 0}"
  name            = "${local.name_prefix}-${var.log_type}"
  log_group_name  = "${aws_cloudwatch_log_group.default.name}"
  filter_pattern  = "${var.filter_pattern}"
  destination_arn = "${aws_cloudformation_stack.aws_central_logging_destination.outputs["Destination"]}"
}
