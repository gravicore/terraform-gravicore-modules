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
  name         = "${azurerm_application_insights.default[each.key].name}-connection-string"
  value        = azurerm_application_insights.default[each.key].connection_string
  key_vault_id = var.key_vault_id
}

locals {
  headers_per_webtest          = { for key, wt in var.webtests : key => wt.request.headers if wt.request.headers != null }
  validation_rules_per_webtest = { for key, wt in var.webtests : key => wt.validation_rules if wt.validation_rules != null }
}



data "azurerm_resource_group" "default" {
  name = var.resource_group_name
}

resource "azapi_resource" "webtests" {
  for_each  = var.create ? var.webtests : {}
  type      = "Microsoft.Insights/webtests@2022-06-15"
  name      = join(var.delimiter, [local.stage_prefix, each.key, module.azure_region.location_short, "webtest"])
  location  = var.az_region
  parent_id = data.azurerm_resource_group.default.id
  tags = merge(
    local.tags,
    { "hidden-link:${azurerm_application_insights.default[each.value.application_insights_key].id}" = "Resource" }
  )


  body = jsonencode({
    properties = {
      Configuration = {
        WebTest = each.value.request.request_body
      }
      Description = each.value.name
      Enabled     = each.value.enabled
      Frequency   = each.value.frequency
      Kind        = each.value.kind
      Locations   = each.value.locations
      Name        = each.value.name
      Request = {
        FollowRedirects        = each.value.request.follow_redirects
        HttpVerb               = each.value.request.http_verb
        ParseDependentRequests = each.value.request.parse_dependent_requests
        RequestBody            = each.value.request.request_body
        RequestUrl             = each.value.request.request_url
        Headers                = local.headers_per_webtest[each.key] != null ? [for h in local.headers_per_webtest[each.key] : { key = h.key, value = h.value }] : []
      }
      RetryEnabled       = each.value.retry_enabled
      SyntheticMonitorId = each.value.synthetic_monitor_id
      Timeout            = each.value.timeout
      ValidationRules = local.validation_rules_per_webtest[each.key] != null ? {
        ContentValidation = local.validation_rules_per_webtest[each.key].content_validation != null ? {
          ContentMatch    = local.validation_rules_per_webtest[each.key].content_validation.content_match
          IgnoreCase      = local.validation_rules_per_webtest[each.key].content_validation.ignore_case
          PassIfTextFound = local.validation_rules_per_webtest[each.key].content_validation.pass_if_text_found
        } : null
        ExpectedHttpStatusCode        = local.validation_rules_per_webtest[each.key].expected_http_status_code
        IgnoreHttpStatusCode          = local.validation_rules_per_webtest[each.key].ignore_http_status_code
        SSLCertRemainingLifetimeCheck = local.validation_rules_per_webtest[each.key].ssl_cert_remaining_lifetime_check
        SSLCheck                      = local.validation_rules_per_webtest[each.key].ssl_check
      } : null
    }
  })
}

