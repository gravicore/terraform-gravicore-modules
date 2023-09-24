# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = "waf"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/waf"
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


variable "custom_rules" {
  description = "List of custom rules for WAF"
  type = list(object({
    name      = optional(string)
    enabled   = optional(bool, true)
    priority  = number
    rule_type = string
    match_conditions = list(object({
      match_variables = list(object({
        variable_name = string
        selector      = optional(string)
      }))
      operator           = string
      negation_condition = optional(bool)
      match_values       = optional(list(string))
      transforms         = optional(list(string))
    }))
    action               = string
    rate_limit_duration  = optional(string)
    rate_limit_threshold = optional(number)
    group_rate_limit_by  = optional(string)
  }))
  default = []
}

variable "policy_settings" {
  description = "WAF policy settings"
  type = object({
    enabled                          = optional(bool)
    mode                             = optional(string)
    request_body_check               = optional(bool)
    file_upload_limit_in_mb          = optional(number)
    max_request_body_size_in_kb      = optional(number)
    request_body_inspect_limit_in_kb = optional(number)
    log_scrubbing = optional(object({
      enabled = optional(bool)
      scrubbing_rule = optional(list(object({
        enabled                 = optional(bool)
        match_variable          = string
        selector_match_operator = optional(string)
        selector                = optional(string)
      })))
    }))
  })
}

variable "managed_rules" {
  description = "Managed rules for WAF"
  type = object({
    exclusions = optional(list(object({
      match_variable          = string
      selector                = string
      selector_match_operator = string
      excluded_rule_set = optional(list(object({
        type    = optional(string)
        version = optional(string)
        rule_group = optional(list(object({
          rule_group_name = string
          excluded_rules  = optional(list(string))
        })))
      })))
    })))
    managed_rule_sets = list(object({
      type    = optional(string)
      version = string
      rule_group_override = optional(list(object({
        rule_group_name = string
        rule = optional(list(object({
          id      = string
          enabled = bool
          action  = string
        })))
      })))
    }))
  })
  default = null
}

