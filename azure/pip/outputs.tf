output "public_ip_mappings" {
  value = { for k, pip in azurerm_public_ip.default : pip.name => pip.ip_address }
}

