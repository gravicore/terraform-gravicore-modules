# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "server_name" {
  type        = string
  default     = ""
  description = "(Required) The name of the SQL Server on which to create the database."
}

variable "create_mode" {
  type        = string
  default     = "DEFAULT"
  description = "(Optional) Specifies how to create the database. Valid values are: Default, Copy, OnlineSecondary, NonReadableSecondary, PointInTimeRestore, Recovery, Restore or RestoreLongTermRetentionBackup. Must be Default to create a new database. Defaults to Default"
}

# variable "import" {
#   type = string
#   default = ""
#   description = "A Database Import block as documented below. create_mode must be set to Default"
# }

variable "source_database_id" {
  type        = string
  default     = ""
  description = "(Optional) The URI of the source database if create_mode value is not Default"
}

variable "restore_point_in_time" {
  type        = string
  default     = ""
  description = "(Optional) The point in time for the restore. Only applies if create_mode is PointInTimeRestore e.g. 2013-11-08T22:00:40Z"
}

variable "edition" {
  type        = string
  default     = "Basic"
  description = "(Optional) The edition of the database to be created. Applies only if create_mode is Default. Valid values are: Basic, Standard, Premium, DataWarehouse, Business, BusinessCritical, Free, GeneralPurpose, Hyperscale, Premium, PremiumRS, Standard, Stretch, System, System2, or Web"
}

variable "collation" {
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
  description = "(Optional) The name of the collation. Applies only if create_mode is Default. Azure default is SQL_LATIN1_GENERAL_CP1_CI_AS. Changing this forces a new resource to be created."
}

variable "max_size_bytes" {
  type        = number
  default     = 0 # ? What should this default to?
  description = "(Optional) The maximum size that the database can grow to. Applies only if create_mode is Default"
}

variable "requested_service_objective_id" {
  type        = string
  default     = ""
  description = "(Optional) A GUID/UUID corresponding to a configured Service Level Objective for the Azure SQL database which can be used to configure a performance level."
}

variable "requested_service_objective_name" {
  type        = string
  default     = ""
  description = "(Optional) The service objective name for the database. Valid values depend on edition and location and may include S0, S1, S2, S3, P1, P2, P4, P6, P11 and ElasticPool. You can list the available names with the CLI: shell az sql db list-editions -l westus -o table"
}

variable "source_database_deletion_date" {
  type        = string
  default     = ""
  description = "(Optional) The deletion date time of the source database. Only applies to deleted databases where create_mode is PointInTimeRestore"
}

variable "elastic_pool_name" {
  type        = string
  default     = ""
  description = "(Optional) The name of the elastic database pool."
}

# * Threat Detection Policy

variable "state" {
  type        = string
  default     = "Enabled"
  description = "(Required) The State of the Policy. Possible values are Enabled, Disabled or New."
}

variable "disabled_alerts" {
  type        = list(string)
  default     = []
  description = "(Optional) Specifies a list of alerts which should be disabled. Possible values include Access_Anomaly, Sql_Injection and Sql_Injection_Vulnerability"
}

variable "email_account_admins" {
  type        = bool
  default     = false
  description = "(Optional) Should the account administrators be emailed when this alert is triggered?"
}

variable "email_addresses" {
  type        = list(string)
  default     = []
  description = "(Optional) A list of email addresses which alerts should be sent to."
}

variable "retention_days" {
  type        = number
  default     = 0 # ? What should this default to?
  description = "(Optional) Specifies the number of days to keep in the Threat Detection audit logs."
}

variable "storage_account_access_key" {
  type        = string
  default     = ""
  description = "(Optional) Specifies the identifier key of the Threat Detection audit storage account. Required if state is Enabled."
}

variable "storage_endpoint" {
  type        = string
  default     = ""
  description = "(Optional) Specifies the blob storage endpoint (e.g. https://example.blob.core.windows.net). This blob storage will hold all Threat Detection audit logs. Required if state is Enabled"
}

# * End Threat Detection Policy

variable "read_scale" {
  type        = bool
  default     = false
  description = "(Optional) Read-only connections will be redirected to a high-available replica."
}

variable "zone_redundant" {
  type        = bool
  default     = false # ? What should this default to?
  description = "(Optional) Whether or not this database is zone redundant, which means the replicas of this database will be spread across multiple availability zones."
}

# TODO: Extended Auditing Policy

variable "storage_account_access_key" {
  type        = string
  default     = ""
  description = "(Optional) Specifies the access key to use for the auditing storage account."
}

variable "storage_endpoint" {
  type        = string
  default     = ""
  description = "(Optional) Specifies the blob storage endpoint (e.g. https://example.blob.core.windows.net)."
}

variable "storage_account_access_key_is_secondary" {
  type        = bool
  default     = false
  description = "(Optional) Specifies whether storage_account_access_key value is the storage's secondary key."
}

variable "retention_in_days" {
  type        = number
  default     = 0 # ? What should this default to?
  description = "(Optional) Specifies the number of days to retain logs for in the storage account."
}

variable "log_monitoring_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Enable audit events to Azure Monitor?"
}

# TODO: End Extended Auditing Policy

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_sql_database" "default" {
  count = var.create ? 1 : 0
  name  = var.name
  tags  = local.tags

  resource_group_name              = var.resource_group_name
  location                         = var.az_location
  server_name                      = var.server_name
  create_mode                      = var.create_mode
  source_database_id               = var.source_database_id
  restore_point_in_time            = var.restore_point_in_time
  edition                          = var.edition
  collation                        = var.collation
  max_size_bytes                   = var.max_size_bytes
  requested_service_objective_id   = var.requested_service_objective_id
  requested_service_objective_name = var.requested_service_objective_name
  source_database_deletion_date    = var.source_database_deletion_date
  elastic_pool_name                = var.elastic_pool_name

  dynamic threat_detection_policy {
    state                                   = var.state
    disabled_alerts                         = var.disabled_alerts
    email_account_admins                    = var.email_account_admins
    email_addresses                         = var.email_addresses
    retention_days                          = var.retention_days
    storage_account_access_key              = var.storage_account_access_key
    storage_endpoint                        = var.storage_endpoint
    storage_account_access_key_is_secondary = var.storage_account_access_key_is_secondary
  }

  read_scale     = var.read_scale
  zone_redundant = var.zone_redundant

  extended_auditing_policy {
    storage_account_access_key              = var.storage_account_access_key
    storage_endpoint                        = var.storage_endpoint
    storage_account_access_key_is_secondary = var.storage_account_access_key_is_secondary
    retention_in_days                       = var.retention_in_days
    log_monitoring_enabled                  = var.log_monitoring_enabled
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------
