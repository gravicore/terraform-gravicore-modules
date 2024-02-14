# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = "conbudg"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/alert"
  description = "The owner and name of the Terraform module"
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


variable "subscription_consumption_budget" {
  description = "Map of Consumption Budgets for Subscriptions."
  type = map(object({
    name            = string
    subscription_id = string
    amount          = number
    time_grain      = optional(string, "Monthly")
    time_period = object({
      start_date = string
      end_date   = optional(string)
    })
    filter = optional(object({
      dimension = optional(list(object({
        name     = string
        operator = optional(string, "In")
        values   = list(string)
      })))
      tag = optional(list(object({
        name     = string
        operator = optional(string, "In")
        values   = list(string)
      })))
    }))
    notifications = list(object({
      enabled        = optional(bool, true)
      threshold      = number
      operator       = string
      threshold_type = optional(string, "Actual")
      contact_emails = optional(list(string))
      contact_groups = optional(list(string))
      contact_roles  = optional(list(string))
    }))
  }))
  default = {}
}

variable "resource_group_consumption" {
  description = "Map of Resource Group Consumption Budgets."
  type = map(object({
    name                = string
    resource_group_id   = optional(string)
    resource_group_name = optional(string)
    amount              = number
    time_grain          = optional(string)
    time_period = object({
      start_date = string
      end_date   = optional(string)
    })
    filter = optional(object({
      dimension = optional(list(object({
        name     = string
        operator = optional(string, "In")
        values   = list(string)
      })))
      tag = optional(list(object({
        name     = string
        operator = optional(string, "In")
        values   = list(string)
      })))
    }))
    notifications = list(object({
      enabled        = optional(bool, true)
      threshold      = number
      operator       = string
      threshold_type = optional(string, "Actual")
      contact_emails = optional(list(string))
      contact_groups = optional(list(string))
      contact_roles  = optional(list(string))
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.resource_group_consumption :
      v.resource_group_id != null || v.resource_group_name != null
    ])
    error_message = "Each entry in resource_group_consumption must have either resource_group_id or resource_group_name specified."
  }
}

