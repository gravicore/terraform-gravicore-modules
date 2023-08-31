# ----------------------------------------------------------------------------------------------------------------------
# Log analytics workspace
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "default" {
  count                              = var.create ? 1 : 0
  name                               = var.name
  location                           = var.az_location
  resource_group_name                = var.resource_group_name
  allow_resource_only_permissions    = var.allow_resource_only_permissions
  local_authentication_disabled      = var.local_authentication_disabled
  sku                                = var.sku
  retention_in_days                  = var.retention_in_days
  daily_quota_gb                     = var.daily_quota_gb
  cmk_for_query_forced               = var.cmk_for_query_forced
  internet_ingestion_enabled         = var.internet_ingestion_enabled
  internet_query_enabled             = var.internet_query_enabled
  reservation_capacity_in_gb_per_day = var.reservation_capacity_in_gb_per_day
  tags                               = local.tags
}

# ----------------------------------------------------------------------------------------------------------------------
# "Log Analytics Contributor" Role assignment
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_role_assignment" "default" {
  for_each             = var.contributors
  scope                = var.resource_group_id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = each.value
}

# ----------------------------------------------------------------------------------------------------------------------
# Security center workspace
# ----------------------------------------------------------------------------------------------------------------------


data "azurerm_subscription" "current" {
}

resource "azurerm_security_center_workspace" "default" {
  count        = var.create ? 1 : 0
  scope        = "/subscriptions/${data.azurerm_subscription.current.display_name.id}"
  workspace_id = concat(azurerm_log_analytics_workspace.default.*.id, [""])[0]
}


# ----------------------------------------------------------------------------------------------------------------------
# Log analytics solutions
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_log_analytics_solution" "default" {
  for_each              = var.solutions
  solution_name         = var.solutions[count.index].solution_name
  location              = var.az_location
  resource_group_name   = var.resource_group_name
  workspace_id          = concat(azurerm_log_analytics_workspace.default.*.id, [""])[0]
  workspace_name        = concat(azurerm_log_analytics_workspace.default.*.name, [""])[0]

  plan {
    publisher = each.value.publisher
    product   = each.value.product
  }

  tags = local.tags
}