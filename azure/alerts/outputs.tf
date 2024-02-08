output "component_name" {
  description = "The name of this Application Insights component."
  value       = { for k, v in azurerm_application_insights.default : k => v.name }
}

output "component_id" {
  description = "The ID of this Application Insights component."
  value       = { for k, v in azurerm_application_insights.default : k => v.id }
}

output "instrumentation_key" {
  description = "The instrumentation key of this Application Insights component."
  value       = { for k, v in azurerm_application_insights.default : k => v.instrumentation_key }
  sensitive   = true
}

output "connection_string" {
  description = "The connection string of this Application Insights component."
  value       = { for k, v in azurerm_application_insights.default : k => v.connection_string }
  sensitive   = true
}

