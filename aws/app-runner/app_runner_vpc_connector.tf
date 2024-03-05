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



# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------


resource "aws_apprunner_vpc_connector" "vpc_connector" {

  vpc_connector_name = "java-poc-vpc-connector"
  subnets            = var.subnet_ids
  security_groups    = var.security_group_ids

}


# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "vpc_connector_arn" {
  value = aws_apprunner_vpc_connector.vpc_connector.arn
}

