# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "claranet/regions/azurerm"
  version      = "6.1.0"
  azure_region = var.region
}


# ----------------------------------------------------------------------------------------------------------------------
# Diagnostic settings resource
# ----------------------------------------------------------------------------------------------------------------------


data "azurerm_monitor_diagnostic_categories" "default" {
  count = local.enabled ? 1 : 0

  resource_id = var.target_resource_id
}


resource "azurerm_monitor_diagnostic_setting" "default" {
  name               = join(var.delimiter, [element(split("/", var.target_resource_id), length(split("/", var.target_resource_id)) - 1), var.name])
  target_resource_id = var.target_resource_id

  storage_account_id             = local.storage_id
  log_analytics_workspace_id     = local.log_analytics_id
  log_analytics_destination_type = local.log_analytics_destination_type
  eventhub_authorization_rule_id = local.eventhub_authorization_rule_id
  eventhub_name                  = local.eventhub_name

  dynamic "enabled_log" {
    for_each = local.log_categories

    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = local.metrics

    content {
      category = metric.key
      enabled  = metric.value.enabled
    }
  }
  lifecycle {
    ignore_changes = [log_analytics_destination_type]
  }
}

