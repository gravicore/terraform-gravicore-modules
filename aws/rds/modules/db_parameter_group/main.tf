resource "aws_db_parameter_group" "this" {
  count = "${var.create ? 1 : 0}"

  name_prefix = "${var.name_prefix}"
  description = "Default database parameter group"
  family      = "${var.family}"

  parameter = ["${var.parameters}"]

  tags = "${merge(var.tags, map("Name", "Default parameter group"))}"

  lifecycle {
    create_before_destroy = true
  }
}
