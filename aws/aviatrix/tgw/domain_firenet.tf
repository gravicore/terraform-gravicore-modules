# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "create_firenet" {
  type        = string
  default     = false
  description = "Create a Firewall Network (FireNet)"
}

variable "firenet_vpc_cidr" {
  type        = string
  default     = "10.130.236.0/22"
  description = "CIDR block of the FireNet VPC"
}

variable "firenet_vpc_name" {
  type        = string
  default     = ""
  description = "Name of the FireNet VPC"
}

# variable "firenet_security_domain" {
#   type        = string
#   default     = "Aviatrix_Firewall_Domain"
#   description = "Name of the Aviatrix Firewall Security Domain"
# }

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Request EIP incease from 5-20

# Create FireNet VPC
# https://docs.aviatrix.com/HowTos/firewall_network_workflow.html#create-a-security-vpc
resource "aviatrix_vpc" "firenet" {
  count  = var.create && var.create_firenet ? 1 : 0
  name   = coalesce(var.firenet_vpc_name, "${local.stage_prefix}-firenet-vpc")
  region = var.aws_region

  account_name         = local.stage_prefix
  cloud_type           = 1
  cidr                 = var.firenet_vpc_cidr
  aviatrix_firenet_vpc = true
}

# Subscribe to AWS Marketplace
# https://docs.aviatrix.com/HowTos/firewall_network_workflow.html#subscribe-to-aws-marketplace

# Launch Aviatrix FireNet Gateway
# https://docs.aviatrix.com/HowTos/firewall_network_workflow.html#launch-aviatrix-firenet-gateway

# Launch Aviatrix FireNet Gateway
# https://docs.aviatrix.com/HowTos/firewall_network_workflow.html#launch-aviatrix-firenet-gateway

# Enable Aviatrix FireNet Gateway
# https://docs.aviatrix.com/HowTos/firewall_network_workflow.html#enable-aviatrix-firenet-gateway

# Attach Aviatrix FireNet gateway to TGW Firewall Domain
# https://docs.aviatrix.com/HowTos/firewall_network_workflow.html#attach-aviatrix-firenet-gateway-to-tgw-firewall-domain

# Launch and Associate Firewall Instance
# https://docs.aviatrix.com/HowTos/firewall_network_workflow.html#a-launch-and-associate-firewall-instance

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "firenet_vpc_id" {
  value       = aviatrix_vpc.firenet[0].vpc_id
  description = "ID of the FireNet VPC"
}

output "firenet_vpc_subnets" {
  value       = aviatrix_vpc.firenet[0].subnets
  description = "List of subnet maps for the FireNet VPC"
}

output "firenet_vpc_subnet_ids" {
  value       = [for subnet in aviatrix_vpc.firenet[0].subnets : subnet.subnet_id]
  description = "List of subnet IDs for the FireNet VPC"
}
