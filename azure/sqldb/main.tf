resource "azurerm_mssql_server" "default" {
  count               = var.create ? 1 : 0
  name                = join(var.delimiter, [local.stage_prefix, var.az_location, "sql", "server"])
  resource_group_name = var.resource_group_name
  location            = var.az_location
  tags                = local.tags

  version                      = var.sql_server_version
  administrator_login          = var.sql_server_administrator_login
  administrator_login_password = var.sql_server_administrator_login_password
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_database" "default" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [local.stage_prefix, var.az_location, "sql", "database"])
  tags  = local.tags

  server_id                   = concat(azurerm_mssql_server.default.*.id, [""])[0]
  auto_pause_delay_in_minutes = var.auto_pause_delay_in_minutes
  create_mode                 = var.create_mode
  creation_source_database_id = var.create_mode != "Default" ? var.creation_source_database_id : null
  collation                   = var.collation
  geo_backup_enabled          = var.geo_backup_enabled
  ledger_enabled              = var.ledger_enabled
  license_type                = var.license_type
  max_size_gb                 = var.max_size_gb
  min_capacity                = var.min_capacity
  restore_point_in_time       = var.create_mode == "PointInTimeRestore" ? var.restore_point_in_time : null
  recover_database_id         = var.create_mode == "Recovery" ? var.recover_database_id : null
  restore_dropped_database_id = var.create_mode == "Restore" ? var.restore_dropped_database_id : null
  read_replica_count          = var.sku_name == "HS_Gen4_1" ? var.read_replica_count : null
  sku_name                    = var.sku_name
}
