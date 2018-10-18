module "subscription_filter_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.1"
  namespace  = "${var.namespace}"
  name       = "${local.name_prefix}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${compact(concat(var.attributes, list("filter")))}"
  tags       = "${local.tags}"
  enabled    = "${var.enabled}"
}

resource "aws_cloudwatch_log_subscription_filter" "default" {
  count           = "${var.enabled == "true" ? 1 : 0}"
  name            = "${local.name_prefix}-${var.log_type}"
  log_group_name  = "${aws_cloudwatch_log_group.default.name}"
  filter_pattern  = "${var.filter_pattern}"
  destination_arn = "${aws_cloudformation_stack.aws_central_logging_destination.outputs["Destination"]}"
}
