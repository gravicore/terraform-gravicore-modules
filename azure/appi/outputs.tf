output "component_name" {
  description = "The name of this Application Insights component."
  value       = { for k, v in azurerm_application_insights.default : k => v.name }
}

output "component_id" {
  description = "The ID of this Application Insights component."
  value       = { for k, v in azurerm_application_insights.default : k => v.id }
}
