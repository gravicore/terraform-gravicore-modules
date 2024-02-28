output "component_name" {
  description = "The name of this Application Insights component."
  value       = { for k, v in azurerm_application_insights.default : k => v.name }
}

output "component_id" {
  description = "The ID of this Application Insights component."
  value       = { for k, v in azurerm_application_insights.default : k => v.id }
}

output "webtest_ids" {
  description = "The IDs of the webtests created for this Application Insights component."
  value       = { for k, v in azurerm_application_insights_standard_web_test.default : k => v.id }
}

output "application_insights_smart_detection_rule_ids" {
  description = "The IDs of the smart detection rules created for this Application Insights component."
  value       = { for rule in azurerm_application_insights_smart_detection_rule.default : rule.name => rule.id }
}
