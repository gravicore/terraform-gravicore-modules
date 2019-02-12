# data "aws_region" "default" {
#   current = "true"
# }

resource "aws_cloudwatch_log_group" "default" {
  count             = "${var.enabled == "true" ? 1 : 0}"
  name              = "${local.name_prefix}-${var.log_type}"
  retention_in_days = "${var.retention_in_days}"
  tags              = "${local.tags}"
}
