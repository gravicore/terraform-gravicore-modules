# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "tgw_vpn_dynamic_connections" {
  type = map(object({
    public_ip        = string
    remote_as_number = number
  }))
  default     = null
  description = "Map of Aviatrix AWS TGW dynamic VPN Connections"
}

variable "tgw_vpn_static_connections" {
  type = map(object({
    public_ip   = string
    remote_cidr = string
  }))
  default     = null
  description = "Map of Aviatrix AWS TGW static VPN Connections"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Create an Aviatrix AWS TGW VPN Connection (dynamic)
resource "aviatrix_aws_tgw_vpn_conn" "tgw_vpn_dynamic_connections" {
  for_each = var.create && var.tgw_vpn_dynamic_connections != null ? var.tgw_vpn_dynamic_connections : {}

  tgw_name          = local.stage_prefix
  route_domain_name = "Default_Domain"
  connection_name   = format("%s-%s-%s", local.stage_prefix, "vpn", each.key)
  public_ip         = each.value.public_ip
  remote_as_number  = each.value.remote_as_number
}

# Create an Aviatrix AWS TGW VPN Connection (static)
resource "aviatrix_aws_tgw_vpn_conn" "tgw_vpn_static_connections" {
  for_each = var.create && var.tgw_vpn_static_connections != null ? var.tgw_vpn_static_connections : {}

  tgw_name          = local.stage_prefix
  route_domain_name = "Default_Domain"
  connection_name   = format("%s-%s-%s", local.stage_prefix, "vpn", each.key)
  public_ip         = each.value.public_ip
  remote_cidr       = each.value.remote_cidr
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# SSM Parameters

module "parameters_tgw_vpn_connections" {
  source      = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/parameters?ref=0.32.0"
  providers   = { aws = aws }
  create      = var.create && var.create_parameters
  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags

  write_parameters = {
    "/${local.stage_prefix}/${var.name}-vpn-dynamic-connections" = { value = jsonencode(aviatrix_aws_tgw_vpn_conn.tgw_vpn_dynamic_connections),
    description = "Map of provisioned Aviatrix AWS TGW dynamic VPN Connections" }
    "/${local.stage_prefix}/${var.name}-vpn-static-connections" = { value = jsonencode(aviatrix_aws_tgw_vpn_conn.tgw_vpn_static_connections),
    description = "Map of provisioned Aviatrix AWS TGW static VPN Connections" }
  }
}

# Outputs

output "tgw_vpn_dynamic_connections" {
  value       = aviatrix_aws_tgw_vpn_conn.tgw_vpn_dynamic_connections
  description = "Map of provisioned Aviatrix AWS TGW dynamic VPN Connections"
}

output "tgw_vpn_static_connections" {
  value       = aviatrix_aws_tgw_vpn_conn.tgw_vpn_static_connections
  description = "Map of provisioned Aviatrix AWS TGW static VPN Connections"
}
