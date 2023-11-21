# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=GDEV-336-release-azure"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# SQL DB resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_mssql_database" "single_database" {
  for_each = try({ for db in var.databases : db.name => db if !var.elastic_pool_enabled }, {})

  name      = local.module_prefix
  server_id = var.mssql_server_id

  sku_name     = var.single_databases_sku_name
  license_type = each.value.license_type

  collation      = var.databases_collation
  max_size_gb    = can(regex("Secondary|OnlineSecondary", each.value.create_mode)) ? null : each.value.max_size_gb
  zone_redundant = can(regex("^DW", var.single_databases_sku_name)) && var.databases_zone_redundant != null ? var.databases_zone_redundant : false

  min_capacity                = can(regex("^GP_S", var.single_databases_sku_name)) ? each.value.min_capacity : null
  auto_pause_delay_in_minutes = can(regex("^GP_S", var.single_databases_sku_name)) ? each.value.auto_pause_delay_in_minutes : null

  read_scale         = can(regex("^P|BC", var.single_databases_sku_name)) && each.value.read_scale != null ? each.value.read_scale : false
  read_replica_count = can(regex("^HS", var.single_databases_sku_name)) ? each.value.read_replica_count : null

  #https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.management.sql.models.database.createmode?view=azure-dotnet
  create_mode = can(regex("^DW", var.single_databases_sku_name)) ? lookup(local.datawarehouse_allowed_create_mode, each.value.create_mode, "Default") : try(lookup(local.standard_allowed_create_mode, each.value.create_mode), "Default")

  creation_source_database_id = can(regex("Copy|Secondary|PointInTimeRestore|Recovery|RestoreExternalBackup|Restore|RestoreExternalBackupSecondary", each.value.create_mode)) ? each.value.creation_source_database_id : null

  restore_point_in_time       = each.value.create_mode == "PointInTimeRestore" ? each.value.restore_point_in_time : null
  recover_database_id         = each.value.create_mode == "Recovery" ? each.value.recover_database_id : null
  restore_dropped_database_id = each.value.create_mode == "Restore" ? each.value.restore_dropped_database_id : null

  storage_account_type = each.value.storage_account_type

  dynamic "threat_detection_policy" {
    for_each = var.threat_detection_policy_enabled ? ["enabled"] : []
    content {
      state                      = "Enabled"
      email_account_admins       = "Enabled"
      email_addresses            = var.alerting_email_addresses
      retention_days             = var.threat_detection_policy_retention_days
      disabled_alerts            = var.threat_detection_policy_disabled_alerts
      storage_endpoint           = var.security_storage_account_blob_endpoint
      storage_account_access_key = var.security_storage_account_access_key
    }
  }

  short_term_retention_policy {
    retention_days           = var.point_in_time_restore_retention_days
    backup_interval_in_hours = var.point_in_time_backup_interval_in_hours
  }

  dynamic "long_term_retention_policy" {
    for_each = coalesce(
      try(var.backup_retention.weekly_retention, ""),
      try(var.backup_retention.monthly_retention, ""),
      try(var.backup_retention.yearly_retention, ""),
      try(var.backup_retention.week_of_year, ""),
      "empty"
    ) == "empty" ? [] : ["enabled"]
    content {
      weekly_retention  = try(format("P%sW", var.backup_retention.weekly_retention), null)
      monthly_retention = try(format("P%sM", var.backup_retention.monthly_retention), null)
      yearly_retention  = try(format("P%sY", var.backup_retention.yearly_retention), null)
      week_of_year      = var.backup_retention.week_of_year
    }
  }

  tags = local.tags
}

resource "azurerm_mssql_database" "elastic_pool_database" {
  for_each = try({ for db in var.databases : db.name => db if var.elastic_pool_enabled }, {})

  name      = local.module_prefix
  server_id = var.mssql_server_id

  sku_name        = "ElasticPool"
  license_type    = each.value.license_type
  elastic_pool_id = one(azurerm_mssql_elasticpool.elastic_pool[*].id)

  collation      = var.databases_collation
  max_size_gb    = can(regex("Secondary|OnlineSecondary", each.value.create_mode)) ? null : each.value.max_size_gb
  zone_redundant = can(regex("^DW", var.single_databases_sku_name)) && var.databases_zone_redundant != null ? var.databases_zone_redundant : false

  #https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.management.sql.models.database.createmode?view=azure-dotnet
  create_mode = try(lookup(local.standard_allowed_create_mode, each.value.create_mode), "Default")

  creation_source_database_id = can(regex("Copy|Secondary|PointInTimeRestore|Recovery|RestoreExternalBackup|Restore|RestoreExternalBackupSecondary", each.value.create_mode)) ? each.value.creation_source_database_id : null

  restore_point_in_time       = each.value.create_mode == "PointInTimeRestore" ? each.value.restore_point_in_time : null
  recover_database_id         = each.value.create_mode == "Recovery" ? each.value.recover_database_id : null
  restore_dropped_database_id = each.value.create_mode == "Restore" ? each.value.restore_dropped_database_id : null

  storage_account_type = each.value.storage_account_type

  dynamic "threat_detection_policy" {
    for_each = var.threat_detection_policy_enabled ? ["enabled"] : []
    content {
      state                      = "Enabled"
      email_account_admins       = "Enabled"
      email_addresses            = var.alerting_email_addresses
      retention_days             = var.threat_detection_policy_retention_days
      disabled_alerts            = var.threat_detection_policy_disabled_alerts
      storage_endpoint           = var.security_storage_account_blob_endpoint
      storage_account_access_key = var.security_storage_account_access_key
    }
  }

  short_term_retention_policy {
    retention_days           = var.point_in_time_restore_retention_days
    backup_interval_in_hours = var.point_in_time_backup_interval_in_hours
  }

  dynamic "long_term_retention_policy" {
    for_each = coalesce(
      try(var.backup_retention.weekly_retention, ""),
      try(var.backup_retention.monthly_retention, ""),
      try(var.backup_retention.yearly_retention, ""),
      try(var.backup_retention.week_of_year, ""),
      "empty"
    ) == "empty" ? [] : ["enabled"]
    content {
      weekly_retention  = try(format("P%sW", var.backup_retention.weekly_retention), null)
      monthly_retention = try(format("P%sM", var.backup_retention.monthly_retention), null)
      yearly_retention  = try(format("P%sY", var.backup_retention.yearly_retention), null)
      week_of_year      = var.backup_retention.week_of_year
    }

  }

  tags = local.tags
}


resource "azurerm_mssql_database_extended_auditing_policy" "elastic_pool_db" {
  for_each = var.databases_extended_auditing_enabled ? try({ for db in var.databases : db.name => db if var.elastic_pool_enabled == true }, {}) : {}

  database_id                             = azurerm_mssql_database.elastic_pool_database[each.key].id
  storage_endpoint                        = var.security_storage_account_blob_endpoint
  storage_account_access_key              = var.security_storage_account_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.databases_extended_auditing_retention_days
}

resource "azurerm_mssql_database_extended_auditing_policy" "single_db" {
  for_each = var.databases_extended_auditing_enabled ? try({ for db in var.databases : db.name => db if var.elastic_pool_enabled == false }, {}) : {}

  database_id                             = azurerm_mssql_database.single_database[each.key].id
  storage_endpoint                        = var.security_storage_account_blob_endpoint
  storage_account_access_key              = var.security_storage_account_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.databases_extended_auditing_retention_days
}

