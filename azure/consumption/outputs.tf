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

