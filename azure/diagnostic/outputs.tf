output "diagnostic_ids" {
  description = "Export diagnostic ID"
  value       = concat(azurerm_monitor_diagnostic_setting.default[*].id, [""])[0]
}

output "all_available_categories" {
  description = "Available log categories of the particular resource"
  value       = data.azurerm_monitor_diagnostic_categories.default
}

