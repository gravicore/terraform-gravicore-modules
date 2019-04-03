# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "create" {
  description = "Whether to create this resource or not?"
  default     = true
}

variable "module_prefix" {
  description = "Creates a unique name beginning with the specified prefix"
}

variable "subnet_ids" {
  type        = "list"
  description = "A list of VPC subnet IDs"
  default     = []
}

variable "tags" {
  type        = "map"
  description = "A mapping of tags to assign to the resource"
  default     = {}
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  count = "${var.create ? 1 : 0}"

  name        = "${var.module_prefix}"
  description = "Database subnet group"
  subnet_ids  = ["${var.subnet_ids}"]

  tags = "${merge(var.tags, map("Name", "RDS_subnet_group"))}"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "this_db_subnet_group_id" {
  description = "The db subnet group name"
  value       = "${element(concat(aws_db_subnet_group.this.*.id, list("")), 0)}"
}

output "this_db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = "${element(concat(aws_db_subnet_group.this.*.arn, list("")), 0)}"
}
