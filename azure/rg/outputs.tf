output "resource_group_ids" {
  value = { for k, v in azurerm_resource_group.default : k => v.id }
}

output "resource_group_names" {
  value = { for k, v in azurerm_resource_group.default : k => v.name }
}

