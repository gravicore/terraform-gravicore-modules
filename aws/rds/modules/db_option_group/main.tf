resource "aws_db_option_group" "this" {
  count = "${var.create ? 1 : 0}"

  name                     = "${var.name_prefix}"
  option_group_description = "${var.option_group_description == "" ? format("Option group for %s", var.identifier) : var.option_group_description}"
  engine_name              = "${var.engine_name}"
  major_engine_version     = "${var.major_engine_version}"

  option = ["${var.options}"]

  tags = "${var.tags}"

  lifecycle {
    create_before_destroy = true
  }
}
