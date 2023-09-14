# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------

module "azure_region" {
  source       = "claranet/regions/azurerm"
  version      = "6.1.0"
  azure_region = var.region
}

# ----------------------------------------------------------------------------------------------------------------------
# Log analytics workspace
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "default" {
  for_each                           = local.workspace_map
  name                               = join(var.delimiter, [local.stage_prefix, each.key, module.azure_region.location_short, var.name])
  location                           = var.region
  resource_group_name                = var.resource_group_name
  allow_resource_only_permissions    = each.value.allow_resource_only_permissions
  local_authentication_disabled      = each.value.local_authentication_disabled
  sku                                = each.value.sku
  retention_in_days                  = each.value.retention_in_days
  daily_quota_gb                     = each.value.daily_quota_gb
  cmk_for_query_forced               = each.value.cmk_for_query_forced
  internet_ingestion_enabled         = each.value.internet_ingestion_enabled
  internet_query_enabled             = each.value.internet_query_enabled
  reservation_capacity_in_gb_per_day = each.value.reservation_capacity_in_gb_per_day

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      read   = timeouts.value.read
      delete = timeouts.value.delete
    }
  }

  tags = local.tags
}


# ----------------------------------------------------------------------------------------------------------------------
# "Log Analytics Contributor" Role assignment
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_role_assignment" "default" {
  for_each = { for idx, ra in local.flat_role_assignments : "${ra.key}-${idx}" => ra }

  scope                = azurerm_log_analytics_workspace.default[each.value.key].id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = each.value.principal_id
}

# ----------------------------------------------------------------------------------------------------------------------
# Security center workspace
# ----------------------------------------------------------------------------------------------------------------------


data "azurerm_subscription" "current" {
}

resource "azurerm_security_center_workspace" "default" {
  for_each = { for key, ws in local.workspace_map : key => ws if ws.security_center_workspace == true }

  scope        = data.azurerm_subscription.current.id
  workspace_id = azurerm_log_analytics_workspace.default[each.key].id
}


# ----------------------------------------------------------------------------------------------------------------------
# Log analytics solutions
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_log_analytics_solution" "default" {
  for_each = {
    for ws_key, ws in local.workspace_map :
    ws_key => { workspace = ws, solutions = ws.solutions } if ws.solutions != null
  }
  dynamic "plan" {
    for_each = each.value.solutions
    content {
      publisher = plan.value.publisher
      product   = plan.value.product
    }
  }

  solution_name         = each.value.solutions[0].solution_name
  location              = var.region
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.default[each.key].id
  workspace_name        = azurerm_log_analytics_workspace.default[each.key].name

  tags = local.tags
}

