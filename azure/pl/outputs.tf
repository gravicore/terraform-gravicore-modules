output "private_link_service_aliases" {
  value = { for key, pls in azurerm_private_link_service.default : key => pls.alias }
}

