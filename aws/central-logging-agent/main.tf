module "vpc_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.1"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${compact(concat(var.attributes, list("vpc")))}"
  tags       = "${var.tags}"
  enabled    = "${var.enabled}"
}

module "flow_log_destination" {
  source         = "${path.module}/central-logging-agent-destination"
  enabled        = "${var.enabled}"
  log_type       = "flow-logs"
  filter_pattern = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action, flowlogstatus]"
}
