# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------
variable "name" {
  type        = string
  default     = "sql"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/sql"
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

variable "server_version" {
  description = "Version of the SQL Server. Valid values are: 2.0 (for v11 server) and 12.0 (for v12 server). See https://www.terraform.io/docs/providers/azurerm/r/sql_server.html#version"
  type        = string
  default     = "12.0"
}

variable "allowed_ip_addresses" {
  description = "List of allowed IP addresses for the PostgreSQL Flexible Server."
  type = list(object({
    rule_name = string
    ip_prefix = string
  }))
  default = null
}

variable "elastic_pool_enabled" {
  description = "True to deploy the databases in an ElasticPool, single databases are deployed otherwise."
  type        = bool
  default     = false
}

variable "elastic_pool_sku" {
  description = <<DESC
    SKU for the Elastic Pool with tier and eDTUs capacity. Premium tier with zone redundancy is mandatory for high availability.
    Possible values for tier are `GeneralPurpose`, `BusinessCritical` for vCore models and `Basic`, `Standard`, or `Premium` for DTU based models.
    See https://docs.microsoft.com/en-us/azure/sql-database/sql-database-dtu-resource-limits-elastic-pools"
DESC

  type = object({
    name     = string,
    capacity = number,
    tier     = string,
    family   = optional(string)
  })
  default = null
}

variable "elastic_pool_license_type" {
  description = "Specifies the license type applied to this database. Possible values are `LicenseIncluded` and `BasePrice`"
  type        = string
  default     = null
}

variable "elastic_pool_max_size_gb" {
  description = "Maximum size of the Elastic Pool in gigabytes"
  type        = string
  default     = null
}

variable "elastic_pool_max_size_bytes" {
  description = "Maximum size of the Elastic Pool in gigabytes"
  type        = string
  default     = null
}

variable "elastic_pool_zone_redundant" {
  description = "True to have the Elastic Pool zone redundant, SKU tier must be Premium to use it. This is mandatory for high availability."
  type        = bool
  default     = false
}

variable "elastic_pool_maintenance_configuration_name" {
  description = "The name of the Public Maintenance Configuration window to apply to the elastic pool."
  type        = string
  default     = null
}

variable "elastic_pool_databases_min_capacity" {
  description = "The minimum capacity (DTU or vCore) all databases are guaranteed in the Elastic Pool. Defaults to 0."
  type        = number
  default     = 0
}

variable "elastic_pool_databases_max_capacity" {
  description = "The maximum capacity (DTU or vCore) any one database can consume in the Elastic Pool. Default to the max Elastic Pool capacity."
  type        = number
  default     = null
}

variable "administrator_login" {
  description = "Administrator login for SQL Server"
  type        = string
}

variable "administrator_password" {
  description = "Administrator password for SQL Server"
  type        = string
}

variable "allowed_subnets_ids" {
  description = "List of Subnet ID to allow to connect to the SQL Instance"
  type        = list(string)
  default     = []
}

variable "ignore_missing_vnet_service_endpoint" {
  description = "List of Subnet ID to allow to connect to the SQL Instance"
  type        = bool
  default     = false
}

variable "tls_minimum_version" {
  description = "The TLS minimum version for all SQL Database associated with the server. Valid values are: `1.0`, `1.1` and `1.2`."
  type        = string
  default     = "1.2"
}

variable "public_network_access_enabled" {
  description = "True to allow public network access for this server"
  type        = bool
  default     = false
}

variable "outbound_network_restriction_enabled" {
  description = "Whether outbound network traffic is restricted for this server"
  type        = bool
  default     = false
}

variable "azuread_administrator" {
  description = "Azure AD Administrator configuration block of this SQL Server."
  type = object({
    login_username              = optional(string)
    object_id                   = optional(string)
    tenant_id                   = optional(string)
    azuread_authentication_only = optional(bool)
  })
  default = null
}

variable "identity" {
  description = "Map of identity configuration."
  type        = map(string)
  default     = null
}

variable "primary_user_assigned_identity_id" {
  description = "Map of primary user identity configuration."
  type        = map(string)
  default     = null
}

variable "connection_policy" {
  description = "The connection policy the server will use. Possible values are `Default`, `Proxy`, and `Redirect`"
  type        = string
  default     = "Default"
}

variable "alerting_email_addresses" {
  description = "List of email addresses to send reports for threat detection and vulnerability assesment"
  type        = list(string)
  default     = []
}

variable "sql_server_extended_auditing_enabled" {
  description = "True to enable extended auditing for SQL Server"
  type        = bool
  default     = false
}

variable "sql_server_vulnerability_assessment_enabled" {
  description = "True to enable vulnerability assessment for this SQL Server"
  type        = bool
  default     = false
}

variable "sql_server_security_alerting_enabled" {
  description = "True to enable security alerting for this SQL Server"
  type        = bool
  default     = false
}

variable "sql_server_extended_auditing_retention_days" {
  description = "Server extended auditing logs retention"
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

variable "security_storage_account_container_name" {
  description = "Storage Account container name where to store SQL Server vulneralibility assessment"
  type        = string
  default     = null
}


locals {
  allowed_subnets = [
    for id in var.allowed_subnets_ids : {
      name      = split("/", id)[10]
      subnet_id = id
    }
  ]

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

