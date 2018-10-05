module "subscription_filter_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.1"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${compact(concat(var.attributes, list("filter")))}"
  tags       = "${var.tags}"
  enabled    = "${var.enabled}"
}

resource "aws_cloudwatch_log_subscription_filter" "default" {
  count           = "${var.enabled == "true" ? 1 : 0}"
  name            = "${module.subscription_filter_label.id}"
  log_group_name  = "${aws_cloudwatch_log_group.default.name}"
  filter_pattern  = "${var.filter_pattern}"
  destination_arn = "arn:aws:logs:${var.aws_region}:${var.root_account}:destination:central-logging-${var.account_id}-Destination"
}
