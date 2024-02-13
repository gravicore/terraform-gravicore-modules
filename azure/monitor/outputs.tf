output "monitor_action_group_name" {
  description = "The name of the Monitor Action Group."
  value       = { for k, v in azurerm_monitor_action_group.default : k => v.name }
}

output "monitor_action_group_id" {
  description = "The ID of the Monitor Action Group."
  value       = { for k, v in azurerm_monitor_action_group.default : k => v.id }
}

output "monitor_metric_alert_name" {
  description = "The name of the Monitor Metric Alert."
  value       = { for k, v in azurerm_monitor_metric_alert.default : k => v.name }
}

output "monitor_metric_alert_id" {
  description = "The ID of the Monitor Metric Alert."
  value       = { for k, v in azurerm_monitor_metric_alert.default : k => v.id }
}

output "monitor_activity_log_alert_name" {
  description = "The name of the Monitor Activity Log Alert."
  value       = { for k, v in azurerm_monitor_activity_log_alert.default : k => v.name }
}

output "monitor_activity_log_alert_id" {
  description = "The ID of the Monitor Activity Log Alert."
  value       = { for k, v in azurerm_monitor_activity_log_alert.default : k => v.id }
}

