output "container_app_id" {
  value = {
    for app in azurerm_container_app.default : app.name => app.id
  }
  sensitive = true
}

