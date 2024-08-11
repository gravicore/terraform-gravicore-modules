output "sentinel_alert_rule_scheduled_info" {
  description = "Map of Sentinel Alert Rule Scheduled names to their details."

  value = {
    for key, resource in azurerm_sentinel_alert_rule_scheduled.default : key => {
      name                       = resource.name
      log_analytics_workspace_id = resource.log_analytics_workspace_id
      display_name               = resource.display_name
      severity                   = resource.severity
      query                      = resource.query
      query_frequency            = resource.query_frequency
      query_period               = resource.query_period
      tactics                    = resource.tactics
      trigger_operator           = resource.trigger_operator
      trigger_threshold          = resource.trigger_threshold
      enabled                    = resource.enabled
      suppression_enabled        = resource.suppression_enabled
      suppression_duration       = resource.suppression_duration
    }
  }
}
