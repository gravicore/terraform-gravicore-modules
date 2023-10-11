# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=release-azure"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# Container Environment
# ----------------------------------------------------------------------------------------------------------------------

# resource "azurerm_resource_group" "default" {
#   count    = var.create ? 1 : 0
#   name     = join(var.delimiter, [local.module_prefix, "rg", "infra"])
#   location = var.az_region
#   tags     = local.tags
# }

# resource "azurerm_management_lock" "default" {
#   count      = var.create && var.lock_level != null ? 1 : 0
#   name       = join(var.delimiter, [azurerm_resource_group.default[count.index].name, "lock"])
#   scope      = azurerm_resource_group.default[count.index].id
#   lock_level = var.lock_level
#   notes      = "Resource Group '${azurerm_resource_group.default[count.index].name}' is locked with '${var.lock_level}' level."
# }

# resource "azapi_resource" "default" {
#   count     = var.create ? 1 : 0
#   type      = "Microsoft.App/managedEnvironments@2023-05-01"
#   name      = local.module_prefix
#   location  = var.az_region
#   parent_id = var.resource_group_id
#   tags      = local.tags
#   body = jsonencode({
#     properties = {
#       # appLogsConfiguration = {
#       #   destination = "log-analytics"
#       #   logAnalyticsConfiguration = {
#       #     customerId = "string"
#       #     sharedKey = null
#       #   }        
#       # }
#       # infrastructureResourceGroup = azurerm_resource_group.default[count.index].id
#       vnetConfiguration = {
#         infrastructureSubnetId = var.infrastructure_subnet_id
#         internal               = var.internal_load_balancer_enabled != null ? true : false
#       }
#       workloadProfiles = var.workload_profiles
#       zoneRedundant    = var.zone_redundant
#     }
#     # kind = "string"
#   })
# }

# output "container_app_environment_id" {
#   value = azapi_resource.default.id
# }


# variable "workload_profiles" {
#   type = list(object({
#     maximumCount        = optional(number)
#     minimumCount        = optional(number)
#     name                = string
#     workloadProfileType = string
#   }))
#   default     = []
#   description = "(Optional) The Workload Profiles to use for the Container Apps Control Plane. Changing this forces a new resource to be created."
# }

# variable "zone_redundant" {
#   type        = bool
#   default     = false
#   description = "(Optional) Should the Container Environment operate in Zone Redundant Mode? Defaults to `false`. Changing this forces a new resource to be created."
# }

# variable "resource_group_id" {
#   type        = string
#   default     = null
#   description = "(Optional) The ID of the Resource Group to create the Container App Environment in. Changing this forces a new resource to be created."
# }

# variable "lock_level" {
#   type        = string
#   default     = null
#   description = "The level of lock to apply to the resource group (e.g. `CanNotDelete`, `ReadOnly`)"
# }

resource "azurerm_container_app_environment" "default" {
  count                          = var.create ? 1 : 0
  location                       = var.az_region
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  name                           = local.module_prefix
  resource_group_name            = var.resource_group_name
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled
  tags                           = local.tags
}

# ----------------------------------------------------------------------------------------------------------------------
# Container Environment Dapr Component
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_app_environment_dapr_component" "default" {
  for_each = var.dapr_component

  component_type               = each.value.component_type
  container_app_environment_id = one(azurerm_container_app_environment.default.*.id)
  name                         = join(var.delimiter, [local.module_prefix, "dapr"])
  version                      = each.value.version
  ignore_errors                = each.value.ignore_errors
  init_timeout                 = each.value.init_timeout
  scopes                       = each.value.scopes

  dynamic "metadata" {
    for_each = each.value.metadata == null ? [] : each.value.metadata

    content {
      name        = metadata.value.name
      secret_name = metadata.value.secret_name
      value       = metadata.value.value
    }
  }
  dynamic "secret" {
    for_each = nonsensitive(toset([for pair in lookup(var.dapr_component_secrets, each.key, []) : pair.name]))

    content {
      name  = secret.key
      value = local.dapr_component_secrets[each.key][secret.key]
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Container Environment Storage
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_app_environment_storage" "storage" {
  for_each = var.env_storage

  access_key                   = var.environment_storage_access_key[each.key]
  access_mode                  = each.value.access_mode
  account_name                 = each.value.account_name
  container_app_environment_id = one(azurerm_container_app_environment.default.*.id)
  name                         = join(var.delimiter, [local.module_prefix, "st"])
  share_name                   = each.value.share_name
}


resource "azurerm_private_dns_a_record" "default" {
  count               = var.internal_load_balancer_enabled && var.dns_a_record != null ? 1 : 0
  name                = var.dns_a_record.name
  zone_name           = var.dns_a_record.zone_name
  resource_group_name = var.dns_a_record.resource_group_name
  ttl                 = var.dns_a_record.ttl
  records             = [azurerm_container_app_environment.default[0].static_ip_address]
}

module "diagnostic" {
  create                = var.create && var.log_analytics_workspace_id != [] ? true : false
  source                = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/diagnostic?ref=release-azure"
  namespace             = var.namespace
  environment           = var.environment
  stage                 = var.stage
  application           = var.application
  az_region             = var.az_region
  target_resource_id    = concat(azurerm_container_app_environment.default.*.id, [""])[0]
  logs_destinations_ids = [var.log_analytics_workspace_id]
}

