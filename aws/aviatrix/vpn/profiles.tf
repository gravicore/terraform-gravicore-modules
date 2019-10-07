# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vpn_profiles" {
  type        = map
  default     = {}
  description = "Map of VPN profiles {'name'={base_rule, users=[], policies=[{action, proto, port, target}]}}"
}

variable "aviatrix_accounts" {
  type        = map
  default     = {}
  description = "Map of Aviatrix Accounts to build VPN profiles from"
}

data "aviatrix_account" "this" {
  for_each     = toset([local.stage_prefix])
  account_name = each.value
}

locals {
  aviatrix_accounts = merge(var.aviatrix_accounts,
    { for id, value in data.aviatrix_account.this : id => merge(value, map("cloud_type", tostring(value.cloud_type))) }
  )

  vpn_profiles = merge(
    { "allow_all" = {
      base_rule = "allow_all"
      policies  = {}
    } },
    { "deny_internal" = {
      base_rule = "allow_all"
      policies = {
        "0" = {
          action = "deny"
          proto  = "all"
          port   = "0:65535"
          target = "10.0.0.0/8"
        },
        "1" = {
          action = "deny"
          proto  = "all"
          port   = "0:65535"
          target = "172.16.0.0/12"
        },
        "2" = {
          action = "deny"
          proto  = "all"
          port   = "0:65535"
          target = "192.168.0.0/16"
        },
      }
    } },
    { for id, value in local.aviatrix_accounts : id => {
      base_rule = "deny_all"
      policies = { "0" = {
        action = "allow"
        proto  = "all"
        port   = "0:65535"
        target = "0.0.0.0/32"
      } }
    } },
    var.vpn_profiles
  )
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aviatrix_vpn_profile" "profiles" {
  for_each = var.create ? local.vpn_profiles : {}

  name      = each.key
  base_rule = each.value.base_rule

  dynamic "policy" {
    for_each = each.value.policies
    content {
      action = policy.value.action
      proto  = policy.value.proto
      port   = policy.value.port
      target = policy.value.target
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "vpn_profiles" {
  value       = aviatrix_vpn_profile.profiles
  description = "Map of Aviatrix VPN profiles"
}