output "resource_group_id" {
  value = concat(azurerm_resource_group.default.*.id, [""])[0]
}

output "resource_group_name" {
  value = concat(azurerm_resource_group.default.*.name, [""])[0]
}
