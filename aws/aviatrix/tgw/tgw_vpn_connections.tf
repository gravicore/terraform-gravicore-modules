# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "tgw_vpn_connections" {
  type        = map(any)
  default     = null
  description = <<EOF
  Map of Aviatrix AWS TGW VPN Connections
tgw_vpn_connections = {
  <id> = {                            string,       (Required) Unique identifier of the location used in naming 
    route_domain_name               = string,       (Required, Default: Default_Domain) The name of a route domain, to which the vpn will be attached
    connection_type                 = string,       (Optional, Default: dynamic) Connection type. Valid values: 'dynamic', 'static'. 'dynamic' stands for a BGP VPN connection; 'static' stands for a static VPN connection
    public_ip                       = string,       (Required) Public IP address. Example: "40.0.0.0"
    remote_cidr                     = string,       (Optional) Remote CIDRs separated by ",". Example: AWS: "16.0.0.0/16,16.1.0.0/16". Required for a static VPN connection
    remote_as_number                = string,       (Optional) AWS side as a number. Integer between 1-4294967294. Example: "12". Required for a dynamic VPN connection
    enable_learned_cidrs_approval   = bool,         (Optional, Default: false) Switch to enable/disable encrypted transit approval for AWS TGW VPN connection. Valid values: true, false. https://docs.aviatrix.com/HowTos/tgw_approval.html
    enable_global_acceleration      = bool,         (Optional, Default: false) Enable Global Acceleration. Type: Boolean
    inside_ip_cidr_tun_1            = string,       (Optional) Inside IP CIDR for Tunnel 1. A /30 CIDR in 169.254.0.0/16
    pre_shared_key_tun_2            = string        (Optional) Pre-Shared Key for Tunnel 1. A 8-64 character string with alphanumeric underscore(_) and dot(.). It cannot start with 0
    inside_ip_cidr_tun_1            = string,       (Optional) Inside IP CIDR for Tunnel 2. A /30 CIDR in 169.254.0.0/16
    pre_shared_key_tun_2            = string,       (Optional) Pre-Shared Key for Tunnel 2. A 8-64 character string with alphanumeric underscore(_) and dot(.). It cannot start with 0
  }
}
EOF
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Create an Aviatrix AWS TGW VPN Connection
resource "aviatrix_aws_tgw_vpn_conn" "tgw_vpn_connections" {
  for_each = var.create && var.tgw_vpn_connections != null ? var.tgw_vpn_connections : {}

  tgw_name                      = local.stage_prefix
  route_domain_name             = lookup(each.value, "route_domain_name", "Default_Domain")
  connection_name               = format("%s-%s-%s", local.stage_prefix, "vpn", each.key)
  connection_type               = lookup(each.value, "connection_type", "dynamic")
  public_ip                     = each.value.public_ip
  remote_cidr                   = lookup(each.value, "remote_cidr", null)
  remote_as_number              = lookup(each.value, "remote_as_number", null)
  enable_learned_cidrs_approval = lookup(each.value, "enable_learned_cidrs_approval", false)
  enable_global_acceleration    = lookup(each.value, "enable_global_acceleration", false)
  inside_ip_cidr_tun_1          = lookup(each.value, "inside_ip_cidr_tun_1", null)
  pre_shared_key_tun_1          = lookup(each.value, "pre_shared_key_tun_1", null)
  inside_ip_cidr_tun_2          = lookup(each.value, "inside_ip_cidr_tun_2", null)
  pre_shared_key_tun_2          = lookup(each.value, "pre_shared_key_tun_2", null)
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# SSM Parameters

resource "aws_ssm_parameter" "tgw_vpn_connections" {
  for_each    = var.create ? aviatrix_aws_tgw_vpn_conn.tgw_vpn_connections : {}
  name        = "/${local.stage_prefix}/${var.name}-${replace(each.value["connection_name"], "${local.module_prefix}-", "")}-vpn-connection"
  description = format("%s %s", var.desc_prefix, "Map of provisioned ${replace(each.value["connection_name"], "${local.module_prefix}-", "")} Aviatrix AWS TGW VPN Connection")
  tags        = local.tags

  type  = "String"
  value = jsonencode(each.value)
  depends_on = [
    aviatrix_aws_tgw_vpn_conn.tgw_vpn_connections,
  ]
}

# Outputs

output "tgw_vpn_connections" {
  value       = aviatrix_aws_tgw_vpn_conn.tgw_vpn_connections
  description = "Map of provisioned Aviatrix AWS TGW VPN Connections"
}
