# ----------------------------------------------------------------------------------------------------------------------
# Sentinel
# ----------------------------------------------------------------------------------------------------------------------


data "azurerm_sentinel_alert_rule_template" "template" {
  for_each                   = { for k, v in var.sentinel_alert_rules : k => v if v.use_template }
  log_analytics_workspace_id = each.value.workspace_resource_id
  display_name               = each.value.display_name
}

resource "azurerm_sentinel_alert_rule_scheduled" "default" {
  for_each = var.sentinel_alert_rules

  name                       = each.value.use_template ? element(split("/", data.azurerm_sentinel_alert_rule_template.template[each.key].id), length(split("/", data.azurerm_sentinel_alert_rule_template.template[each.key].id)) - 1) : each.value.name
  log_analytics_workspace_id = each.value.workspace_resource_id
  display_name               = each.value.display_name
  severity                   = each.value.use_template ? data.azurerm_sentinel_alert_rule_template.template[each.key].scheduled_template[0].severity : each.value.severity
  query                      = each.value.use_template ? data.azurerm_sentinel_alert_rule_template.template[each.key].scheduled_template[0].query : each.value.query
  query_frequency            = each.value.use_template ? data.azurerm_sentinel_alert_rule_template.template[each.key].scheduled_template[0].query_frequency : each.value.query_frequency
  query_period               = each.value.use_template ? data.azurerm_sentinel_alert_rule_template.template[each.key].scheduled_template[0].query_period : each.value.query_period
  tactics                    = each.value.use_template ? data.azurerm_sentinel_alert_rule_template.template[each.key].scheduled_template[0].tactics : each.value.tactics
  trigger_operator           = each.value.use_template ? data.azurerm_sentinel_alert_rule_template.template[each.key].scheduled_template[0].trigger_operator : each.value.trigger_operator
  trigger_threshold          = each.value.use_template ? data.azurerm_sentinel_alert_rule_template.template[each.key].scheduled_template[0].trigger_threshold : each.value.trigger_threshold

  enabled              = each.value.enabled
  suppression_enabled  = each.value.suppression_enabled
  suppression_duration = each.value.suppression_duration

  dynamic "incident" {
    for_each = each.value.incident != null ? [each.value.incident] : []
    content {
      create_incident_enabled = incident.value.create_incident_enabled
      dynamic "grouping" {
        for_each = incident.value.grouping != null ? [incident.value.grouping] : []
        content {
          enabled                 = grouping.value.enabled
          lookback_duration       = grouping.value.lookback_duration
          reopen_closed_incidents = grouping.value.reopen_closed_incidents
          entity_matching_method  = grouping.value.entity_matching_method
        }
      }
    }
  }

  dynamic "alert_details_override" {
    for_each = each.value.alert_details_override != null ? [each.value.alert_details_override] : []
    content {
      description_format   = alert_details_override.value.description_format
      display_name_format  = alert_details_override.value.display_name_format
      severity_column_name = alert_details_override.value.severity_column_name
      tactics_column_name  = alert_details_override.value.tactics_column_name

      dynamic "dynamic_property" {
        for_each = alert_details_override.value.dynamic_property
        content {
          name  = dynamic_property.value.name
          value = dynamic_property.value.value
        }
      }
    }
  }

  dynamic "entity_mapping" {
    for_each = each.value.entity_mapping
    content {
      entity_type = entity_mapping.value.entity_type
      dynamic "field_mapping" {
        for_each = entity_mapping.value.field_mapping
        content {
          identifier  = field_mapping.value.identifier
          column_name = field_mapping.value.column_name
        }
      }
    }
  }

  dynamic "event_grouping" {
    for_each = each.value.event_grouping != null ? [each.value.event_grouping] : []
    content {
      aggregation_method = event_grouping.value.aggregation_method
    }
  }
}
