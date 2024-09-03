output "policy_definition_ids" {
  value       = { for k, v in azurerm_policy_definition.default : k => v.id }
  description = "Map of Azure policy definition IDs"
}

output "management_group_policy_assignment_ids" {
  value       = { for k, v in azurerm_management_group_policy_assignment.default : k => v.id }
  description = "Map of management group policy assignment IDs"
}

output "subscription_policy_assignment_ids" {
  value       = { for k, v in azurerm_subscription_policy_assignment.default : k => v.id }
  description = "Map of subscription policy assignment IDs"
}

output "resource_group_policy_assignment_ids" {
  value       = { for k, v in azurerm_resource_group_policy_assignment.default : k => v.id }
  description = "Map of resource group policy assignment IDs"
}

output "resource_policy_assignment_ids" {
  value       = { for k, v in azurerm_resource_policy_assignment.default : k => v.id }
  description = "Map of resource policy assignment IDs"
}

