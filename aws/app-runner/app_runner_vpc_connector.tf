# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------


variable "vpc_id" {
  type        = string
  description = "VPC ID to connect to App Runner VPC Connector"
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs to associate App Runner VPC Connector"
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "A list of additional security group IDs to allow access to the App Runner VPC Connector"
}

variable "create_vpc_connector" {
  type        = bool
  default     = true
  description = "Flag to create the VPC Connector"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------


resource "aws_apprunner_vpc_connector" "vpc_connector" {
  count              = var.create_vpc_connector ? 1 : 0
  vpc_connector_name = "${var.service_name}-vpc-connector"
  subnets            = var.subnet_ids
  security_groups    = var.security_group_ids

}


# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "vpc_connector_arn" {
  value = var.create_vpc_connector ? aws_apprunner_vpc_connector.vpc_connector[0].arn : null
}
