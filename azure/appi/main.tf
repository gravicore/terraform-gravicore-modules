# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=0.46.0"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# Application Insights
# ----------------------------------------------------------------------------------------------------------------------


resource "azurerm_application_insights" "default" {
  for_each                              = var.create ? var.application_insights : {}
  name                                  = join(var.delimiter, [local.stage_prefix, each.key, module.azure_region.location_short, var.name])
  resource_group_name                   = var.resource_group_name
  location                              = var.az_region
  application_type                      = each.value.application_type
  daily_data_cap_in_gb                  = each.value.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = each.value.daily_data_cap_notifications_disabled
  sampling_percentage                   = each.value.sampling_percentage
  disable_ip_masking                    = each.value.disable_ip_masking
  workspace_id                          = each.value.workspace_id
  retention_in_days                     = each.value.retention_in_days
  local_authentication_disabled         = each.value.local_authentication_disabled
  internet_ingestion_enabled            = each.value.internet_ingestion_enabled
  internet_query_enabled                = each.value.internet_query_enabled
  force_customer_storage_for_profiler   = each.value.force_customer_storage_for_profiler
  tags                                  = local.tags
}

resource "azurerm_key_vault_secret" "application_insights_connection_string" {
  depends_on = [
    azurerm_application_insights.default,
  ]
  for_each     = var.create ? var.application_insights : {}
  name         = azurerm_application_insights.default[each.key].name
  value        = azurerm_application_insights.default[each.key].connection_string
  key_vault_id = var.key_vault_id
}

