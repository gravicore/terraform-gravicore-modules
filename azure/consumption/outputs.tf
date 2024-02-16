
output "subscription_consumption_budget_id" {
  description = "The ID of the Subscription Consumption Budgets."
  value       = { for k, v in azurerm_consumption_budget_subscription.default : k => v.id }
}

output "resource_group_consumption_budget_id" {
  description = "The ID of the Resource Group Consumption Budgets."
  value       = { for k, v in azurerm_consumption_budget_resource_group.default : k => v.id }
}

output "cost_anomaly_alert_id" {
  description = "The ID of the Cost Anomaly Alert."
  value       = azurerm_cost_anomaly_alert.default[0].id
}

output "subscription_cost_management_view_id" {
  description = "The ID of the Subscription Cost Management View."
  value       = { for k, v in azurerm_subscription_cost_management_view.default : k => v.id }
}

output "cost_management_scheduled_action_id" {
  description = "The ID of the Cost Management Scheduled Action."
  value       = { for k, v in azurerm_cost_management_scheduled_action.default : k => v.id }
}
