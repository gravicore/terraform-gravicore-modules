output "application_gateway_id" {
  value = concat(azurerm_application_gateway.default[*].id, [""])[0]
}

