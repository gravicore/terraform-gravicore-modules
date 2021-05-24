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

  policy_deny_private = {
    "-1" = {
      action = "deny"
      proto  = "all"
      port   = "0:65535"
      target = "10.0.0.0/8"
    },
    "-2" = {
      action = "deny"
      proto  = "all"
      port   = "0:65535"
      target = "172.16.0.0/12"
    },
    "-3" = {
      action = "deny"
      proto  = "all"
      port   = "0:65535"
      target = "192.168.0.0/16"
    },
  }

  vpn_profiles = merge(
    { "deny_all" = {
      base_rule = "allow_all"
      policies = { "-1" = {
        action = "deny"
        proto  = "all"
        port   = "0:65535"
        target = "0.0.0.0/0"
      } }
    } },
    { "internet_access" = {
      base_rule = "allow_all"
      policies  = local.policy_deny_private
    } },
    { for id, value in local.aviatrix_accounts : id => {
      base_rule = "allow_all"
      policies  = local.policy_deny_private
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
  users     = lookup(local.vpn_profile_users, each.key, [])

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

# SSM Parameters

module "parameters_vpn_profiles" {
  source = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/parameters?ref=0.32.0"
  # source      = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/parameters?ref=GRVDEV-81-Create-Aviatrix-modules"
  providers   = { aws = aws }
  create      = var.create && var.create_parameters
  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags

  write_parameters = {
    "/${local.stage_prefix}/${var.name}-profile-names" = { value = join(",", [for k, v in aviatrix_vpn_profile.profiles : k]), type = "StringList"
    description = "List of Aviatrix VPN profile names" }
  }
}

# Outputs

output "aviatrix_vpn_profiles" {
  value       = aviatrix_vpn_profile.profiles
  description = "Map of Aviatrix VPN profiles"
}

output "aviatrix_vpn_profile_names" {
  value       = [for k, v in aviatrix_vpn_profile.profiles : k]
  description = "List of Aviatrix VPN profile names"
}