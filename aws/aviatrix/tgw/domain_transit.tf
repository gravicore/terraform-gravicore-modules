# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "create_transit_network" {
  type        = string
  default     = false
  description = "Create a Transit Network"
}

variable "transit_vpc_cidr" {
  type        = string
  default     = "10.130.252.0/22"
  description = "CIDR block of the Transit VPC"
}

variable "transit_vpc_name" {
  type        = string
  default     = ""
  description = "Name of the Transit VPC"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Request EIP incease from 5-20

# Create Transit VPC
resource "aviatrix_vpc" "transit" {
  count  = var.create && var.create_transit_network ? 1 : 0
  name   = coalesce(var.transit_vpc_name, "${local.stage_prefix}-transit-vpc")
  region = var.aws_region

  account_name         = local.stage_prefix
  cloud_type           = 1
  cidr                 = var.transit_vpc_cidr
  aviatrix_transit_vpc = true
}

# Create Cloud Gateway w/ HA
# t3.small

# Create OnPrem Gateway w/ HA
# t3.small

# Create Transit Domain

# Attach Transit VPC to Transit Domain

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "transit_vpc_id" {
  value       = aviatrix_vpc.transit[0].vpc_id
  description = "ID of the Transit VPC"
}

output "transit_vpc_subnets" {
  value       = aviatrix_vpc.transit[0].subnets
  description = "List of subnet maps for the Transit VPC"
}

output "transit_vpc_subnet_ids" {
  value       = [for subnet in aviatrix_vpc.transit[0].subnets : subnet.subnet_id]
  description = "List of subnet IDs for the Transit VPC"
}
