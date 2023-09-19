output "vnet_id" {
  value = concat(azurerm_virtual_network.default.*.id, [""])[0]
}

output "subnets_info" {
  value = { for s in azurerm_subnet.default : s.name => s }
}

output "subnet_nsg_details" {
  value = { for s in azurerm_network_security_group.default : s.name => s }
}