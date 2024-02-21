terraform {
  required_version = ">= 0.12"
}


resource "azurerm_postgresql_flexible_server_database" "default" {
  for_each  = var.azurerm_postgresql_flexible_server_database
  name      = each.value.name
  server_id = each.value.server_id
  collation = each.value.collation
  charset   = each.value.charset
  lifecycle {
    prevent_destroy = true
  }
}


variable "azurerm_postgresql_flexible_server_database" {
  type = map(object({
    name      = string
    charset   = optional(string, "UTF8")
    collation = optional(string, "en_US.utf8")
    server_id = string
  }))
  default = {}
}


output "azurerm_postgresql_flexible_server_database_ids" {
  value = { for key, db in azurerm_postgresql_flexible_server_database.default : key => db.id }
}

