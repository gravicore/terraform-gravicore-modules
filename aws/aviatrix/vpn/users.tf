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
  default     = null
  description = "A map of VPN users {user_name={user_email, profiles=[]}}"
}

locals {
  vpn_users = var.vpn_users != null ? var.vpn_users : { for user_name, profiles in var.vpn_user_names : lower(user_name) => {
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

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "vpn_users" {
  value       = aviatrix_vpn_user.users
  description = "Map of provisioned VPN users"
}

output "vpn_user_names" {
  value       = var.vpn_user_names
  description = "A list of VPN user names and associated VPN profiles"
}
