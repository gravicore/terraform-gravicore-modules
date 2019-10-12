# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vpn_user_names" {
  type        = map
  default     = {}
  description = "A list of VPN user names and associated VPN profiles"
}

variable "vpn_users" {
  type        = map
  default     = {}
  description = "A map of VPN users {user_name={user_email, profiles=[]}}"
}

locals {
  vpn_users = length(var.vpn_users) > 0 ? var.vpn_users : { for user_name, profiles in var.vpn_user_names : lower(user_name) => {
    user_email = join("", flatten(regexall("^(?:(.*@.*\\..*))?$", lower(user_name))))
    profiles   = profiles
  } }
  vpn_profile_users = transpose({ for k, v in local.vpn_users : k => v.profiles })
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aviatrix_vpn_user" "users" {
  for_each = var.create ? local.vpn_users : {}

  vpc_id     = var.vpc_id
  gw_name    = local.module_prefix
  user_name  = each.key
  user_email = each.value.user_email
}

locals {
  vpn_user_vpcs = { for k, v in aviatrix_vpn_user.users : k => v.vpc_id if v.vpc_id != "" }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# Outputs

output "aviatrix_vpn_users" {
  description = "Map of provisioned VPN users"
  value       = aviatrix_vpn_user.users
}

output "aviatrix_vpn_user_names" {
  description = "Map of VPN user names and associated VPN profiles"
  value       = var.vpn_user_names
}

output "aviatrix_vpn_profile_users" {
  description = "Map of VPN Profiles and their associated VPN user names"
  value       = local.vpn_profile_users
}
