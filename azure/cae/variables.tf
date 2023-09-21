# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------


variable "name" {
  type        = string
  default     = "cae"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/cae"
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


variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "(Optional) The ID for the Log Analytics Workspace to link this Container Apps Managed Environment to. Changing this forces a new resource to be created."
}

variable "infrastructure_subnet_id" {
  type        = string
  default     = null
  description = "(Optional) The existing Subnet to use for the Container Apps Control Plane. Changing this forces a new resource to be created."
}

variable "internal_load_balancer_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Should the Container Environment operate in Internal Load Balancing Mode? Defaults to `false`. Changing this forces a new resource to be created."
}
variable "dapr_component" {
  type = map(object({
    component_type = string
    version        = string
    ignore_errors  = optional(bool, false)
    init_timeout   = optional(string, "5s")
    scopes         = optional(list(string))
    metadata = optional(set(object({
      name        = string
      secret_name = optional(string)
      value       = string
    })))
  }))
  default     = {}
  description = "(Optional) The Dapr component to deploy."
  nullable    = false
}

variable "dapr_component_secrets" {
  type = map(list(object({
    name  = string
    value = string
  })))
  default     = {}
  description = "(Optional) The secrets of the Dapr components. The key of the map should be aligned with the corresponding Dapr component."
  nullable    = false
  sensitive   = true
}

variable "env_storage" {
  type = map(object({
    account_name = string
    share_name   = string
    access_mode  = string
  }))
  default     = {}
  description = "(Optional) Manages a Container App Environment Storage, writing files to this file share to make data accessible by other systems."
  nullable    = false
}

variable "environment_storage_access_key" {
  type        = map(string)
  default     = null
  description = "(Optional) The Storage Account Access Key. The key of the map should be aligned with the corresponding environment storage."
  sensitive   = true
}

locals {
  dapr_component_secrets = { for k, v in var.dapr_component_secrets : k => { for i in v : i.name => i.value } }
}

