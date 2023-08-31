# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------
variable "az_location" {
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

variable "tags" {
  type = any
  default = {
    env         = "dev",
    project     = "sf-sa",
    description = "managed by Terraform"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Log Analytics variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = ""
  description = "The name of the log analytics workspace"

}

variable "resource_group_name" {
  type        = string
  default     = ""
  description = "The resource group of the log analytics workspace"
}

variable "allow_resource_only_permissions" {
  type        = bool
  default     = true
  description = "Specifies if the log Analytics Workspace allow users accessing to data associated with resources they have permission to view, without permission to workspace"
}

variable "local_authentication_disabled" {
  type        = bool
  default     = false
  description = "Specifies if the log Analytics workspace should enforce authentication using Azure AD"
}

variable "sku" {
  type        = string
  default     = "PerGB2018"
  description = "Specifies the SKU of the Log Analytics Workspace Free, PerNode, Premium, Standard, Standalone, Unlimited, CapacityReservation, and PerGB2018"
}

variable "retention_in_days" {
  type        = number
  default     = "7"
  description = "The workspace data retention in days. Possible values are either 7 (Free Tier only) or range between 30 and 730"
}

variable "daily_quota_gb" {
  type        = number
  default     = -1
  description = "The workspace daily quota for ingestion in GB"
}

variable "cmk_for_query_forced" {
  type        = bool
  default     = false
  description = " Is Customer Managed Storage mandatory for query management"
}

variable "internet_ingestion_enabled" {
  type        = bool
  default     = true
  description = "Should the Log Analytics Workspace support ingestion over the Public Internet? "
}

variable "internet_query_enabled" {
  type        = bool
  default     = true
  description = "The capacity reservation level in GB for this workspace"
}

variable "reservation_capacity_in_gb_per_day" {
  type        = number
  default     = ""
  description = "The capacity reservation level in GB for this workspace. Possible values are 100, 200, 300, 400, 500, 1000, 2000 and 5000"
}


# ----------------------------------------------------------------------------------------------------------------------
# "Log Analytics Contributor" role assignment variables
# ----------------------------------------------------------------------------------------------------------------------

variable "contributors" {
  type        = list(string)
  default     = []
  description = "The object ids of the users who can contribute law"
}

variable "resource_group_id" {
  type        = string
  default     = ""
  description = "The scope on which the log anlaytics contributor role should be assigned"
}


# ----------------------------------------------------------------------------------------------------------------------
# Security center workspace variables
# ----------------------------------------------------------------------------------------------------------------------

variable "subscription_id" {
  type        = string
  default     = ""
  description = "The Azure subscription ID"
}

# ----------------------------------------------------------------------------------------------------------------------
# Log analytics solutions variables
# ----------------------------------------------------------------------------------------------------------------------

variable "solutions" {
  type = map(object({
    name      = string
    publisher = string
    product   = string
  }))
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
  default     = "Grvc:"
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
  description = "Concatenation of `namespace`, `environment`, `stage` and `name`"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `environment`, `stage`, `name`"
}

locals {
  environment_prefix = coalesce(var.environment_prefix, join(var.delimiter, compact([var.namespace, var.environment])))
  stage_prefix       = coalesce(var.stage_prefix, join(var.delimiter, compact([local.environment_prefix, var.stage])))
  module_prefix      = coalesce(var.module_prefix, join(var.delimiter, compact([local.stage_prefix, var.name])))

  business_tags = {
    namespace          = var.namespace
    environment        = var.environment
    environment_prefix = local.environment_prefix
  }
  technical_tags = {
    stage       = var.stage
    module      = var.name
    repository  = var.repository
    az_location = var.az_location
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