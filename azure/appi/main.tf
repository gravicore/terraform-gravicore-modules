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


resource "azurerm_application_insights_standard_web_test" "default" {
  for_each = var.create ? var.standard_web_test : {}

  name                    = join(var.delimiter, [local.stage_prefix, each.key, module.azure_region.location_short, "webtest"])
  resource_group_name     = var.resource_group_name
  location                = var.az_region
  application_insights_id = azurerm_application_insights.default[each.value.application_insights_key].id
  geo_locations           = each.value.geo_locations
  description             = each.value.description
  enabled                 = each.value.enabled
  frequency               = each.value.frequency
  retry_enabled           = each.value.retry_enabled
  timeout                 = each.value.timeout

  dynamic "request" {
    for_each = each.value.request == null ? [] : ["enabled"]
    content {
      url                              = request.value.request_url
      body                             = request.value.request_body
      http_verb                        = request.value.request_method
      follow_redirects_enabled         = request.value.follow_redirects_enabled
      parse_dependent_requests_enabled = request.value.parse_dependent_requests_enabled

      dynamic "header" {
        for_each = request.value.headers == null ? [] : ["enabled"]
        content {
          name  = headers.value.name
          value = headers.value.value
        }
      }
    }
  }

  dynamic "validation_rules" {
    for_each = each.value.validation_rules == null ? [] : ["enabled"]
    content {
      expected_status_code        = validation_rules.value.expected_status_code
      ssl_cert_remaining_lifetime = validation_rules.value.ssl_cert_remaining_lifetime
      ssl_check_enabled           = validation_rules.value.ssl_check_enabled

      dynamic "content" {
        for_each = validation_rules.value.content == null ? [] : ["enabled"]
        content {
          content_match      = content.value.content_match
          ignore_case        = content.value.ignore_case
          pass_if_text_found = content.value.pass_if_text_found
        }
      }
    }
  }

  tags = local.tags
}




variable "standard_web_test" {
  description = "Map of standard web test configurations"
  type = map(object({
    name                    = string
    resource_group_name     = string
    location                = string
    application_insights_id = string
    geo_locations           = list(string)
    description             = string
    enabled                 = bool
    frequency               = number
    retry_enabled           = bool
    timeout                 = number
    validation_rules = list(object({
      name            = string
      validation_type = string
      validation_text = string
    }))
    request_url           = string
    request_method        = string
    request_headers       = map(string)
    request_body          = string
    request_parse_depends = list(string)
  }))
  default = {}
}
