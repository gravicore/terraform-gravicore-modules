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

variable "policy_definitions" {
  description = "Map of policy definitions with their respective attributes."
  type = map(object({
    display_name              = string,
    description               = string,
    policy_rule_content       = string,
    policy_parameters_content = string,
    policy_mode               = string,
    policy_mgmt_group_name    = optional(string),
  }))
  default = {}
}

variable "policy_assignments" {
  description = "Map with maps to configure assignments. Map key is the name of the assignment."
  type = map(object({
    display_name                 = string,
    description                  = string,
    scope_id                     = string,
    scope_type                   = string,
    parameters                   = optional(any),
    identity_type                = optional(string, "SystemAssigned"),
    identity_ids                 = optional(list(string)),
    enforce                      = optional(bool, true),
    policy_definition_id         = optional(string),
    custom_policy_definition_key = optional(string),
  }))

  validation {
    condition = alltrue([
      can([for p in var.policy_assignments : contains(["subscription", "management-group", "resource-group", "resource"], lower(p.scope_type))]),
      alltrue([for p in var.policy_assignments : (try(p.policy_definition_key, "") != "" || try(p.policy_definition_id, "") != "")]),
      alltrue([for p in var.policy_assignments : (p.identity_type == "SystemAssigned" || (length(coalesce(p.identity_ids, [])) > 0))])
    ])
    error_message = "The `policy_assignments[*].scope_type` value must be valid. Possible values are `subscription`, `management-group`, `resource-group` or `resource`. Additionally, if `policy_definition_key` is null, `policy_definition_id` must not be null, and if `identity_type` is not `SystemAssigned`, `identity_ids` must not be null or empty."
  }
}

variable "policy_assignment_remediation" {
  description = "Map with maps to configure assignments. Map key is the name of the assignment."
  type = map(object({
    name                  = string
    scope_id              = string
    policy_assignment_id  = optional(string)
    policy_assignment_key = optional(string)
    location_filters      = optional(list(string))

  }))
  default = {}
}

