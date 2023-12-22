output "vnet_id" {
  value = concat(azurerm_virtual_network.default.*.id, [""])[0]
}

output "subnets_ids" {
  value = { for key, resource in azurerm_subnet.default : key => resource.id }
}

output "subnet_nsg_details" {
  value = { for key, resource in azurerm_network_security_group.default : key => resource.id }
}

