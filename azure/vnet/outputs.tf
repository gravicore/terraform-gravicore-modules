output "vnet_ids" {
  value = { for key, resource in azurerm_virtual_network.default : key => resource.id }
}

output "subnets_ids" {
  value = { for key, resource in azurerm_subnet.default : key => resource.id }
}

output "subnet_nsg_details" {
  value = { for key, resource in azurerm_network_security_group.default : key => resource.id }
}

