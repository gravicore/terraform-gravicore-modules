# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------
variable "name" {
  type        = string
  default     = "sentinel"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/sentinel"
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
  module_prefix      = coalesce(var.module_prefix, join(var.delimiter, compact([local.stage_prefix, var.application, var.name])))

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

variable "sentinel_alert_rules" {
  description = "Map of Sentinel Alert Rules with optional template data source usage"
  type = map(object({
    use_template          = bool
    display_name          = optional(string)
    name                  = optional(string)
    name                  = optional(string)
    workspace_resource_id = optional(string)
    severity              = optional(string)
    query                 = optional(string)
    query_frequency       = optional(string)
    query_period          = optional(string)
    tactics               = optional(list(string))
    trigger_operator      = optional(string)
    trigger_threshold     = optional(number)
    description           = optional(string)
    enabled               = optional(bool, true)
    suppression_enabled   = optional(bool, false)
    suppression_duration  = optional(string)
    incident = optional(object({
      create_incident_enabled = bool
      grouping = optional(object({
        enabled                 = bool
        lookback_duration       = optional(string, "PT5M")
        reopen_closed_incidents = optional(bool, false)
        entity_matching_method  = optional(string, "AnyAlert")
        by_entities = optional(list(object({
          entity_type = string
        })))
        by_alert_details = optional(list(object({
          alert_detail_type = string
        })))
        by_custom_details = optional(list(object({
          custom_detail_key = string
        })))
      }))
    }))
    alert_details_override = optional(object({
      description_format   = optional(string)
      display_name_format  = optional(string)
      severity_column_name = optional(string)
      tactics_column_name  = optional(string)
      dynamic_property = optional(list(object({
        name  = string
        value = string
      })))
    }))
    entity_mapping = optional(list(object({
      entity_type = string
      field_mapping = list(object({
        identifier  = string
        column_name = string
      }))
    })))
    event_grouping = optional(object({
      aggregation_method = string
    }))
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "The Log Analytics Workspace ID"
  type        = string
  default     = null
}

