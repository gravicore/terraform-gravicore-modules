# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vnet_cidr_block" {
  default     = "10.0.0.0/16"
  description = "(Required) The address space that is used the virtual network. You can supply more than one address space."
}

variable "dns_servers" {
  type        = list(any)
  default     = null
  description = "(Optional) List of IP addresses of DNS servers"
}

variable "edge_zone" {
  type        = string
  default     = null
  description = "(Optional) Specifies the Edge Zone within the Azure Region where this Virtual Network should exist. Changing this forces a new Virtual Network to be created."
}

variable "flow_timeout_in_minutes" {
  type        = number
  default     = null
  description = "(Optional) The flow timeout in minutes for the Virtual Network, which is used to enable connection tracking for intra-VM flows. Possible values are between 4 and 30 minutes."
}

variable "az_max_count" {
  type        = number
  default     = 2
  description = "Sets the maximum number of Availability Zones (up to 3)"
}

variable "bgp_community" {
  type        = string
  default     = null
  description = "(Optional) The BGP community attribute in format <as-number>:<community-value>."
}

# variable "ddos_protection_plan" {
#   type        = map(any)
#   default     = {}
#   description = <<EOD
#   (Optional) A ddos_protection_plan block of the format:
#     {
#       id = (Required) The ID of DDoS Protection Plan.
#       enable = (Required) Enable/disable DDoS Protection Plan on Virtual Network.
#     }
#   EOD
# }

variable "vpc_public_subnets" {
  type        = list(string)
  default     = []
  description = "The public subnets of the VPC to use"
}

variable "vpc_private_subnets" {
  type        = list(string)
  default     = []
  description = "The private subnets of the VPC to use"
}

variable "vpc_internal_subnets" {
  type        = list(string)
  default     = null
  description = "The internal subnets (no NAT access) of the VPC to use"
}

locals {
  vpc_public_subnets = var.vpc_public_subnets != null ? coalescelist(var.vpc_public_subnets, compact([
    var.az_max_count >= 1 ? cidrsubnet(var.vnet_cidr_block, 6, 0) : "",
    var.az_max_count >= 2 ? cidrsubnet(var.vnet_cidr_block, 6, 1) : "",
    var.az_max_count >= 3 ? cidrsubnet(var.vnet_cidr_block, 6, 2) : "",
  ])) : []
  vpc_private_subnets = var.vpc_private_subnets != null ? coalescelist(var.vpc_private_subnets, compact([
    var.az_max_count >= 1 ? cidrsubnet(var.vnet_cidr_block, 4, 1) : "",
    var.az_max_count >= 2 ? cidrsubnet(var.vnet_cidr_block, 4, 2) : "",
    var.az_max_count >= 3 ? cidrsubnet(var.vnet_cidr_block, 4, 3) : "",
  ])) : []
  vpc_internal_subnets = var.vpc_internal_subnets != null ? coalescelist(var.vpc_internal_subnets, compact([
    var.az_max_count >= 1 ? cidrsubnet(var.vnet_cidr_block, 2, 1) : "",
    var.az_max_count >= 2 ? cidrsubnet(var.vnet_cidr_block, 2, 2) : "",
    var.az_max_count >= 3 ? cidrsubnet(var.vnet_cidr_block, 2, 3) : "",
  ])) : []
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_network" "default" {
  #  TODO: Add key-pairs
  count               = var.create ? 1 : 0
  name                = join(var.delimiter, [local.stage_prefix, "vpc-1"])
  location            = var.az_location
  resource_group_name = var.resource_group_name
  tags                = local.tags

  bgp_community           = var.bgp_community == null ? null : join(":", ["12076", var.bgp_community])
  address_space           = var.vnet_cidr_block
  dns_servers             = var.dns_servers
  edge_zone               = var.edge_zone
  flow_timeout_in_minutes = var.flow_timeout_in_minutes

  dynamic "subnet" {
    for_each = local.vpc_public_subnets
    content {
      # TODO: insert number value on name
      name           = join(var.delimiter, [local.module_prefix, "public", index(local.vvpc_private_subnets, each.key)])
      address_prefix = subnet.key
    }
  }

  dynamic "subnet" {
    for_each = local.vpc_private_subnets

    content {
      # TODO: insert number value on name
      name           = join(var.delimiter, [local.module_prefix, "private", index(local.vvpc_private_subnets, subnet.key)])
      address_prefix = subnet.key
    }
  }

  dynamic "subnet" {
    for_each = local.vpc_internal_subnets

    content {
      # TODO: insert number value on name
      name           = join(var.delimiter, [local.module_prefix, "intra", index(local.vvpc_private_subnets, subnet.key)])
      address_prefix = subnet.key
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------


output "test" {
  value = local.vpc_public_subnets
}
