# Below is the Terraform code to create a Container App Environment using the azapi_resource resource.
# It's tested since azurerm does not support the Container App Environment resource fully yet.
# For production implementations, use the azurerm resource instead for now until we test below for all use cases.


# data "azurerm_log_analytics_workspace" "default" {
#   count               = var.log_analytics_workspace_id != null ? 1 : 0
#   name                = regex(".*workspaces/(.*?)$", var.log_analytics_workspace_id)[0]
#   resource_group_name = regex(".*resourceGroups/(.*?)/.*", var.log_analytics_workspace_id)[0]
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
#       appLogsConfiguration = {
#         destination = var.log_analytics_workspace_id != null ? "log-analytics" : null
#         logAnalyticsConfiguration = {
#           customerId = var.log_analytics_workspace_id != null ? data.azurerm_log_analytics_workspace.default[0].workspace_id : null
#           sharedKey  = var.log_analytics_workspace_id != null ? data.azurerm_log_analytics_workspace.default[0].primary_shared_key : null
#         }
#       }
#       vnetConfiguration = {
#         infrastructureSubnetId = var.infrastructure_subnet_id
#         internal               = var.internal_load_balancer_enabled != null ? true : false
#       }
#       workloadProfiles = var.workload_profiles
#       zoneRedundant    = var.zone_redundant
#     }
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
