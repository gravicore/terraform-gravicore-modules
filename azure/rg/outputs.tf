output "resource_group_name" {
  description = "The name of the Resource Group"
  value       = concat(azurerm_resource_group.default.*.name, [])[0]
}
