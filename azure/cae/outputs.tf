output "container_app_environment_id" {
  value = concat(azurerm_container_app_environment.default.*.id, [""])[0]
}

output "static_ip_adress" {
  value = var.internal_load_balancer_enabled ? concat(azurerm_container_app_environment.default.*.static_ip_address, [""])[0] : null
}

