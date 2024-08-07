# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = "monitor"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/monitor"
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

variable "target_resource_ids" {
  description = "The ID of the resource to monitor"
  type        = list(string)
  default     = []
}


variable "action_group" {
  description = "Defines the action group for alerts"
  type = map(object({
    short_name = optional(string)
    enabled    = optional(bool, true)
    location   = optional(string, "global")
    sms_receivers = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })), [])
    voice_receivers = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })), [])
    email_receivers = optional(list(object({
      name                    = string
      email_address           = string
      use_common_alert_schema = optional(bool, true)
    })), [])
  }))
  default = {}
}


variable "metric_alerts" {
  description = "Map of metric Alerts"
  type = map(object({
    action_group_key         = optional(string)
    action_group_id          = optional(string)
    description              = optional(string, null)
    resource_group_name      = optional(string)
    scopes                   = optional(list(string), [])
    enabled                  = optional(bool, true)
    auto_mitigate            = optional(bool, true)
    severity                 = optional(number, 3)
    frequency                = optional(string, "PT5M")
    window_size              = optional(string, "PT5M")
    target_resource_type     = optional(string, null)
    target_resource_location = optional(string, null)
    criteria = optional(list(object({
      metric_namespace       = string
      metric_name            = string
      aggregation            = string
      operator               = string
      threshold              = number
      skip_metric_validation = optional(bool, false)
      dimension = optional(list(object({
        name     = string
        operator = optional(string, "Include")
        values   = list(string)
      })), [])
    })), [])
    dynamic_criteria = optional(list(object({
      metric_namespace         = string
      metric_name              = string
      aggregation              = string
      operator                 = string
      alert_sensitivity        = optional(string, "Medium")
      evaluation_total_count   = optional(number, 4)
      evaluation_failure_count = optional(number, 4)
      ignore_data_before       = optional(string)
      skip_metric_validation   = optional(bool, false)
      dimension = optional(list(object({
        name     = string
        operator = optional(string, "Include")
        values   = list(string)
      })), [])
    })), [])
    application_insights_web_test_location_availability_criteria = optional(object({
      web_test_id           = string
      component_id          = string
      failed_location_count = number
    }), null)
  }))

  default = {}

  validation {
    condition = alltrue([
      for key, value in var.metric_alerts : value.action_group_id != null || value.action_group_key != null
    ])
    error_message = "Each metric alert must have either an action_group_id or an action_group_key defined."
  }
}


variable "activity_log_alerts" {
  description = "Map of Activity log Alerts."
  type = map(object({
    description         = optional(string)
    resource_group_name = optional(string)
    action_group_key    = optional(string)
    action_group_id     = optional(string)
    scopes              = list(string)
    criteria = object({
      operation_name = optional(string)
      category       = optional(string, "Recommendation")
      level          = optional(string, "Error")
      status         = optional(string)

      resource_provider = optional(string)
      resource_type     = optional(string)
      resource_group    = optional(string)
      resource_id       = optional(string)
    })
    service_health = optional(object({
      events    = optional(string, "Incident")
      locations = optional(string, "Global")
      services  = optional(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, value in var.activity_log_alerts : value.action_group_id != null || value.action_group_key != null
    ])
    error_message = "Each metric alert must have either an action_group_id or an action_group_key defined."
  }
}


variable "portal_dashboards" {
  type = map(object({
    file_path = string
    file_vars = map(string)
  }))
  default = {}
}

variable "application_insights_workbooks" {
  type = map(object({
    uuid        = string
    source_id   = optional(string, "azure monitor")
    category    = optional(string, "workbook")
    description = optional(string)
    file_path   = string
    file_vars   = map(string)
  }))
  default = {}
}

variable "scheduled_query_rules_alerts" {
  description = "Map of Scheduled Query Rules Alerts"
  type = map(object({
    action_group_key                  = optional(string)
    action_group_id                   = optional(string)
    description                       = optional(string, null)
    resource_group_name               = optional(string)
    enabled                           = optional(bool, true)
    severity                          = optional(number, 2)
    evaluation_frequency              = optional(string, "PT5M")
    window_duration                   = optional(string, "PT5M")
    scopes                            = list(string)
    auto_mitigation_enabled           = optional(bool, false)
    workspace_alerts_storage_enabled  = optional(bool, false)
    display_name                      = optional(string, "")
    query_time_range_override         = optional(string, "PT1H")
    skip_query_validation             = optional(bool, false)
    mute_actions_after_alert_duration = optional(string, "PT1H")
    target_resource_types             = optional(list(string), [])
    criteria = object({
      query                   = string
      time_aggregation_method = string
      threshold               = number
      operator                = string
      resource_id_column      = optional(string)
      metric_measure_column   = optional(string)
      dimension = optional(list(object({
        name     = string
        operator = optional(string, "Include")
        values   = list(string)
      })), [])
      failing_periods = object({
        minimum_failing_periods_to_trigger_alert = number
        number_of_evaluation_periods             = number
      })
    })
    action_groups     = optional(list(string), [])
    custom_properties = optional(map(string), {})

    identity = object({
      type         = string
      identity_ids = optional(list(string), [])
    })
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, value in var.scheduled_query_rules_alerts : value.action_group_id != null || value.action_group_key != null
    ])
    error_message = "Each scheduled query rules alert must have either an action_group_id or an action_group_key defined."
  }
}
