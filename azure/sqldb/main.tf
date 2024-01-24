# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=0.46.0"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# SQL DB resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_mssql_database" "single_database" {
  for_each = var.elastic_pool_enabled ? {} : var.databases

  name      = join(var.delimiter, compact([local.stage_prefix, var.application, module.azure_region.location_short, each.value.prefix, var.name]))
  server_id = var.mssql_server_id

  sku_name     = each.value.single_database_sku_name
  license_type = each.value.license_type

  collation      = each.value.databases_collation
  max_size_gb    = can(regex("Secondary|OnlineSecondary", each.value.create_mode)) ? null : each.value.max_size_gb
  zone_redundant = can(regex("^DW", each.value.single_database_sku_name)) && each.value.zone_redundant != null ? each.value.zone_redundant : false

  min_capacity                = can(regex("^GP_S", each.value.single_database_sku_name)) ? each.value.min_capacity : null
  auto_pause_delay_in_minutes = can(regex("^GP_S", each.value.single_database_sku_name)) ? each.value.auto_pause_delay_in_minutes : null

  read_scale         = can(regex("^P|BC", each.value.single_database_sku_name)) && each.value.read_scale != null ? each.value.read_scale : false
  read_replica_count = can(regex("^HS", each.value.single_database_sku_name)) ? each.value.read_replica_count : null

  #https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.management.sql.models.database.createmode?view=azure-dotnet
  create_mode = can(regex("^DW", each.value.single_database_sku_name)) ? lookup(local.datawarehouse_allowed_create_mode, each.value.create_mode, "Default") : try(lookup(local.standard_allowed_create_mode, each.value.create_mode), "Default")

  creation_source_database_id = can(regex("Copy|Secondary|PointInTimeRestore|Recovery|RestoreExternalBackup|Restore|RestoreExternalBackupSecondary", each.value.create_mode)) ? each.value.creation_source_database_id : null

  restore_point_in_time       = each.value.create_mode == "PointInTimeRestore" ? each.value.restore_point_in_time : null
  recover_database_id         = each.value.create_mode == "Recovery" ? each.value.recover_database_id : null
  restore_dropped_database_id = each.value.create_mode == "Restore" ? each.value.restore_dropped_database_id : null

  storage_account_type = each.value.storage_account_type

  dynamic "threat_detection_policy" {
    for_each = each.value.threat_detection_policy == null ? [] : [each.value.threat_detection_policy]
    content {
      state                      = threat_detection_policy.value.state
      email_account_admins       = threat_detection_policy.value.email_account_admins
      email_addresses            = threat_detection_policy.value.email_addresses
      retention_days             = threat_detection_policy.value.retention_days
      disabled_alerts            = threat_detection_policy.value.disabled_alerts
      storage_endpoint           = threat_detection_policy.value.storage_endpoint
      storage_account_access_key = threat_detection_policy.value.storage_account_access_key
    }
  }

  dynamic "short_term_retention_policy" {
    for_each = each.value.short_term_retention_policy == null ? [] : [each.value.short_term_retention_policy]
    content {
      retention_days           = short_term_retention_policy.value.retention_days
      backup_interval_in_hours = short_term_retention_policy.value.backup_interval_in_hours
    }
  }

  dynamic "long_term_retention_policy" {
    for_each = coalesce(
      try(each.value.long_term_retention_policy.weekly_retention, ""),
      try(each.value.long_term_retention_policy.monthly_retention, ""),
      try(each.value.long_term_retention_policy.yearly_retention, ""),
      try(each.value.long_term_retention_policy.week_of_year, ""),
      "empty"
    ) == "empty" ? [] : ["enabled"]
    content {
      weekly_retention  = try(format("P%sW", each.value.long_term_retention_policy.weekly_retention), null)
      monthly_retention = try(format("P%sM", each.value.long_term_retention_policy.monthly_retention), null)
      yearly_retention  = try(format("P%sY", each.value.long_term_retention_policy.yearly_retention), null)
      week_of_year      = each.value.long_term_retention_policy.week_of_year
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = local.tags
}

resource "azurerm_mssql_database" "elastic_pool_database" {
  for_each = var.elastic_pool_enabled ? var.databases : {}

  name      = join(var.delimiter, compact([local.stage_prefix, var.application, module.azure_region.location_short, each.value.prefix, var.name]))
  server_id = var.mssql_server_id

  sku_name        = "ElasticPool"
  license_type    = each.value.license_type
  elastic_pool_id = var.elastic_pool_id

  collation      = each.value.databases_collation
  max_size_gb    = can(regex("Secondary|OnlineSecondary", each.value.create_mode)) ? null : each.value.max_size_gb
  zone_redundant = can(regex("^DW", each.value.single_database_sku_name)) && each.value.zone_redundant != null ? each.value.zone_redundant : false

  #https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.management.sql.models.database.createmode?view=azure-dotnet
  create_mode = try(lookup(local.standard_allowed_create_mode, each.value.create_mode), "Default")

  creation_source_database_id = can(regex("Copy|Secondary|PointInTimeRestore|Recovery|RestoreExternalBackup|Restore|RestoreExternalBackupSecondary", each.value.create_mode)) ? each.value.creation_source_database_id : null

  restore_point_in_time       = each.value.create_mode == "PointInTimeRestore" ? each.value.restore_point_in_time : null
  recover_database_id         = each.value.create_mode == "Recovery" ? each.value.recover_database_id : null
  restore_dropped_database_id = each.value.create_mode == "Restore" ? each.value.restore_dropped_database_id : null

  storage_account_type = each.value.storage_account_type

  dynamic "threat_detection_policy" {
    for_each = each.value.threat_detection_policy == null ? [] : each.value.threat_detection_policy
    content {
      state                      = threat_detection_policy.value.state
      email_account_admins       = threat_detection_policy.value.email_account_admins
      email_addresses            = threat_detection_policy.value.email_addresses
      retention_days             = threat_detection_policy.value.retention_days
      disabled_alerts            = threat_detection_policy.value.disabled_alerts
      storage_endpoint           = threat_detection_policy.value.storage_endpoint
      storage_account_access_key = threat_detection_policy.value.storage_account_access_key
    }
  }

  dynamic "short_term_retention_policy" {
    for_each = each.value.short_term_retention_policy == null ? [] : [each.value.short_term_retention_policy]
    content {
      retention_days           = short_term_retention_policy.value.retention_days
      backup_interval_in_hours = short_term_retention_policy.value.backup_interval_in_hours
    }
  }

  dynamic "long_term_retention_policy" {
    for_each = coalesce(
      try(each.value.long_term_retention_policy.weekly_retention, ""),
      try(each.value.long_term_retention_policy.monthly_retention, ""),
      try(each.value.long_term_retention_policy.yearly_retention, ""),
      try(each.value.long_term_retention_policy.week_of_year, ""),
      "empty"
    ) == "empty" ? [] : ["enabled"]
    content {
      weekly_retention  = try(format("P%sW", each.value.long_term_retention_policy.weekly_retention), null)
      monthly_retention = try(format("P%sM", each.value.long_term_retention_policy.monthly_retention), null)
      yearly_retention  = try(format("P%sY", each.value.long_term_retention_policy.yearly_retention), null)
      week_of_year      = each.value.long_term_retention_policy.week_of_year
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = local.tags
}


resource "azurerm_mssql_database_extended_auditing_policy" "elastic_pool_db" {
  for_each = var.databases_extended_auditing_enabled && var.elastic_pool_enabled ? var.databases : {}

  database_id                             = azurerm_mssql_database.elastic_pool_database[each.key].id
  storage_endpoint                        = var.security_storage_account_blob_endpoint
  storage_account_access_key              = var.security_storage_account_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.databases_extended_auditing_retention_days
}

resource "azurerm_mssql_database_extended_auditing_policy" "single_db" {
  for_each = var.databases_extended_auditing_enabled && var.elastic_pool_enabled == false ? var.databases : {}

  database_id                             = azurerm_mssql_database.single_database[each.key].id
  storage_endpoint                        = var.security_storage_account_blob_endpoint
  storage_account_access_key              = var.security_storage_account_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.databases_extended_auditing_retention_days
}

