# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "default_aws_security_group_vpc_id" {
  type        = string
  default     = ""
  description = "vpc_id of default security group"
}

variable "skip_region_validation" {
  type        = string
  default     = "false"
  description = "skip validation on certain regions due to bug"
}

variable "default_security_group_rules" {
  type        = string
  default     = "true"
  description = "apply default security group rules"
}
variable "delete_default_vpcs" {
  type        = string
  default     = "false"
  description = "delete default vpcs from region"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_default_security_group" "default" {
  count  = var.default_security_group_rules == "true" ? 1 : 0
  vpc_id = var.default_aws_security_group_vpc_id
}

resource "null_resource" "delete_default_vpcs" {
  count = var.delete_default_vpcs == "true" ? 1 : 0

  provisioner "local-exec" {
    command = "python ./scripts/delete-vpcs.py ${var.default_aws_security_group_vpc_id} ${var.aws_region}"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------