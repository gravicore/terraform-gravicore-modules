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
  connection_name   = each.key
  public_ip         = each.value.public_ip
  remote_as_number  = each.value.remote_as_number
}

# Create an Aviatrix AWS TGW VPN Connection (static)
resource "aviatrix_aws_tgw_vpn_conn" "tgw_vpn_static_connections" {
  for_each = var.create && var.tgw_vpn_static_connections != null ? var.tgw_vpn_static_connections : {}

  tgw_name          = local.stage_prefix
  route_domain_name = "Default_Domain"
  connection_name   = each.key
  public_ip         = each.value.public_ip
  remote_cidr       = each.value.remote_cidr
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "tgw_vpn_dynamic_connections" {
  value       = aviatrix_aws_tgw_vpn_conn.tgw_vpn_dynamic_connections
  description = "Map of provisioned Aviatrix AWS TGW dynamic VPN Connections"
}

output "tgw_vpn_static_connections" {
  value       = aviatrix_aws_tgw_vpn_conn.tgw_vpn_static_connections
  description = "Map of provisioned Aviatrix AWS TGW static VPN Connections"
}
