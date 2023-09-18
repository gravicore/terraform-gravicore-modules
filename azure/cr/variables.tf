# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = "cr"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/cr"
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
    region     = var.region
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
variable "sku" {
  description = "The SKU name of the the container registry. Possible values are `Classic` (which was previously `Basic`), `Basic`, `Standard` and `Premium`."
  type        = string
  default     = "Standard"
}

variable "admin_enabled" {
  description = "Whether the admin user is enabled."
  type        = bool
  default     = false
}

variable "georeplication_locations" {
  description = <<DESC
  A list of Azure locations where the Ccontainer Registry should be geo-replicated. Only activated on Premium SKU.
  Supported properties are:
    location                  = string
    zone_redundancy_enabled   = bool
    regional_endpoint_enabled = bool
    tags                      = map(string)
  or this can be a list of `string` (each element is a location)
DESC
  type        = any
  default     = []
}

variable "images_retention_enabled" {
  description = "Specifies whether images retention is enabled (Premium only)."
  type        = bool
  default     = false
}

variable "images_retention_days" {
  description = "Specifies the number of images retention days."
  type        = number
  default     = 90
}

variable "azure_services_bypass_allowed" {
  description = "Whether to allow trusted Azure services to access a network restricted Container Registry."
  type        = bool
  default     = false
}

variable "trust_policy_enabled" {
  description = "Specifies whether the trust policy is enabled (Premium only)."
  type        = bool
  default     = false
}

variable "allowed_cidrs" {
  description = "List of CIDRs to allow on the registry."
  default     = []
  type        = list(string)
}

variable "allowed_subnets" {
  description = "List of VNet/Subnet IDs to allow on the registry."
  default     = []
  type        = list(string)
}

variable "public_network_access_enabled" {
  description = "Whether the Container Registry is accessible publicly."
  type        = bool
  default     = true
}

variable "data_endpoint_enabled" {
  description = "Whether to enable dedicated data endpoints for this Container Registry? (Only supported on resources with the Premium SKU)."
  default     = false
  type        = bool
}

variable "identity_type" {
  description = "The type of managed identity to use. Possible values are SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  default     = "SystemAssigned"
}

variable "user_assigned_identity_ids" {
  description = "List of user-assigned identity ids to be assigned. Required if identity_type is UserAssigned or SystemAssigned, UserAssigned."
  default     = []
  type        = list(string)
}


variable "quarantine_policy_enabled" {
  description = "Specifies whether the quarantine policy is enabled (Premium only)."
  type        = bool
  default     = false
}

variable "export_policy_enabled" {
  description = "Specifies whether the export policy is enabled (Premium only)."
  type        = bool
  default     = true
}

variable "zone_redundancy_enabled" {
  description = "Specifies whether zone redundancy is enabled (Premium only)."
  type        = bool
  default     = false
}

variable "anonymous_pull_enabled" {
  description = "Specifies whether anonymous pull is enabled."
  type        = bool
  default     = false
}

# ----------------------------------------------------------------------------------------------------------------------
# PEP Module Variables
# ----------------------------------------------------------------------------------------------------------------------
variable "pep_variables" {
  type        = any
  description = "Variables that need to be passed onto the pep module"
  default     = ""
}

