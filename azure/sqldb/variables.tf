# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------
variable "name" {
  type        = string
  default     = "sqldb"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/sqldb"
  description = "The owner and name of the Terraform module"
}

variable "az_region" {
  type        = string
  default     = ""
  description = "The Azure region to deploy module into"
}

variable "resource_group_name" {
  type        = string
  default     = ""
  description = "The name of the Azure resource group"
}

variable "create" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources"
}

# ----------------------------------------------------------------------------------------------------------------------
# Platform Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

# Recommended

variable "namespace" {
  type        = string
  default     = ""
  description = "Namespace, which could be your organization abbreviation, client name, etc. (e.g. Gravicore 'grv', HashiCorp 'hc')"
}

variable "environment" {
  type        = string
  default     = ""
  description = "The isolated environment the module is associated with (e.g. Shared Services `shared`, Application `app`)"
}

variable "stage" {
  type        = string
  default     = ""
  description = "The development stage (i.e. `dev`, `stg`, `prd`)"
}

variable "application" {
  type        = string
  default     = ""
  description = "The application name (i.e. `apex`, `portal`)"
}

variable "repository" {
  type        = string
  default     = ""
  description = "The repository where the code referencing the module is stored"
}

# Optional

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional map of tags (e.g. business_unit, cost_center)"
}

variable "desc_prefix" {
  type        = string
  default     = "Grvcr:"
  description = "The prefix to add to any descriptions attached to resources"
}

variable "environment_prefix" {
  type        = string
  default     = ""
  description = "Concatenation of `namespace` and `environment`"
}

variable "stage_prefix" {
  type        = string
  default     = ""
  description = "Concatenation of `namespace`, `environment` and `stage`"
}

variable "module_prefix" {
  type        = string
  default     = ""
  description = "Concatenation of `namespace`, `environment`, `stage`, `application`, `region` and `name`"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `environment`, `stage`, `application`, `region` and `name`"
}

locals {
  environment_prefix = coalesce(var.environment_prefix, join(var.delimiter, compact([var.namespace, var.environment])))
  stage_prefix       = coalesce(var.stage_prefix, join(var.delimiter, compact([local.environment_prefix, var.stage])))
  module_prefix      = coalesce(var.module_prefix, join(var.delimiter, compact([local.stage_prefix, var.application, module.azure_region.location_short, var.name])))

  business_tags = {
    namespace          = var.namespace
    environment        = var.environment
    environment_prefix = local.environment_prefix
  }
  technical_tags = {
    stage      = var.stage
    module     = var.name
    repository = var.repository
    region     = var.az_region
  }
  automation_tags = {
    terraform_module = var.terraform_module
    stage_prefix     = local.stage_prefix
    module_prefix    = local.module_prefix
  }
  security_tags = {}

  tags = merge(
    local.business_tags,
    local.technical_tags,
    local.automation_tags,
    local.security_tags,
    var.tags
  )
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "mssql_server_id" {
  description = "The ID of the SQL Server to deploy the databases to."
  type        = string
  default     = ""
}

variable "elastic_pool_enabled" {
  description = "True to deploy the databases in an ElasticPool, single databases are deployed otherwise."
  type        = bool
  default     = false
}

variable "single_databases_sku_name" {
  description = "Specifies the name of the SKU used by the database. For example, `GP_S_Gen5_2`, `HS_Gen4_1`, `BC_Gen5_2`. Use only if `elastic_pool_enabled` variable is set to `false`. More documentation [here](https://docs.microsoft.com/en-us/azure/azure-sql/database/service-tiers-general-purpose-business-critical)"
  type        = string
  default     = "GP_Gen5_2"
}

variable "create_databases_users" {
  description = "True to create a user named <db>_user on each database with generated password and role db_owner."
  type        = bool
  default     = true
}

variable "custom_users" {
  description = <<DESC
    List of objects for custom users creation.
    Password are generated.
    These users are created within the "custom_users" submodule.
DESC
  type = list(object({
    name     = string
    database = string
    roles    = optional(list(string))
  }))
  default = []
}

variable "databases" {
  description = "List of the databases configurations for this server."
  type = list(object({
    name                        = string
    license_type                = optional(string)
    max_size_gb                 = number
    create_mode                 = optional(string)
    min_capacity                = optional(number)
    auto_pause_delay_in_minutes = optional(number)
    read_scale                  = optional(string)
    read_replica_count          = optional(number)
    creation_source_database_id = optional(string)
    restore_point_in_time       = optional(string)
    recover_database_id         = optional(string)
    restore_dropped_database_id = optional(string)
    storage_account_type        = optional(string, "Geo")
    database_extra_tags         = optional(map(string), {})
  }))
  default = []
}

variable "backup_retention" {
  description = "Definition of long term backup retention for all the databases in this SQL Server."
  type = object({
    weekly_retention  = optional(number)
    monthly_retention = optional(number)
    yearly_retention  = optional(number)
    week_of_year      = optional(number)
  })
  default = {}
}

variable "databases_collation" {
  description = "SQL Collation for the databases"
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "databases_zone_redundant" {
  description = "True to have databases zone redundant, which means the replicas of the databases will be spread across multiple availability zones. This property is only settable for `Premium` and `Business Critical` databases."
  type        = bool
  default     = null
}

variable "point_in_time_restore_retention_days" {
  description = "Point In Time Restore configuration. Value has to be between `7` and `35`"
  type        = number
  default     = 7
  validation {
    condition     = var.point_in_time_restore_retention_days >= 7 && var.point_in_time_restore_retention_days <= 35
    error_message = "The PITR retention should be between 7 and 35 days."
  }
}

variable "point_in_time_backup_interval_in_hours" {
  description = "The hours between each differential backup. This is only applicable to live databases but not dropped databases. Value has to be 12 or 24. Defaults to 12 hours."
  type        = number
  default     = 12
  validation {
    condition     = var.point_in_time_backup_interval_in_hours == 12 || var.point_in_time_backup_interval_in_hours == 24
    error_message = "The PITR retention should be 12 or 24 hours."
  }
}

variable "alerting_email_addresses" {
  description = "List of email addresses to send reports for threat detection and vulnerability assesment"
  type        = list(string)
  default     = []
}

variable "threat_detection_policy_enabled" {
  description = "True to enable thread detection policy on the databases"
  type        = bool
  default     = false
}

variable "threat_detection_policy_retention_days" {
  description = "Specifies the number of days to keep in the Threat Detection audit logs"
  type        = number
  default     = 7
}

variable "threat_detection_policy_disabled_alerts" {
  description = "Specifies a list of alerts which should be disabled. Possible values include `Access_Anomaly`, `Sql_Injection` and `Sql_Injection_Vulnerability`"
  type        = list(string)
  default     = []
}

variable "databases_extended_auditing_enabled" {
  description = "True to enable extended auditing for SQL databases"
  type        = bool
  default     = false
}

variable "databases_extended_auditing_retention_days" {
  description = "Databases extended auditing logs retention"
  type        = number
  default     = 30
}

variable "security_storage_account_blob_endpoint" {
  description = "Storage Account blob endpoint used to store security logs and reports"
  type        = string
  default     = null
}

variable "security_storage_account_access_key" {
  description = "Storage Account access key used to store security logs and reports"
  type        = string
  default     = null
}

locals {

  databases_users = var.create_databases_users ? [
    for db in var.databases : {
      username = format("%s_user", replace(db.name, "-", "_"))
      database = db.name
      roles    = ["db_owner"]
    }
  ] : []

  standard_allowed_create_mode = {
    "a" = "Default"
    "b" = "Copy"
    "c" = "Secondary"
    "d" = "PointInTimeRestore"
    "e" = "Restore"
    "f" = "Recovery"
    "g" = "RestoreExternalBackup"
    "h" = "RestoreExternalBackup"
    "i" = "RestoreLongTermRetentionBackup"
    "j" = "OnlineSecondary"
  }

  datawarehouse_allowed_create_mode = {
    "a" = "Default"
    "b" = "PointInTimeRestore"
    "c" = "Restore"
    "d" = "Recovery"
    "e" = "RestoreExternalBackup"
    "f" = "RestoreExternalBackup"
    "g" = "OnlineSecondary"
  }
}

