# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = "kv"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/kv"
  description = "The owner and name of the Terraform module"
}

variable "region" {
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
# Keyvault Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "key_vault_sku_pricing_tier" {
  description = "The name of the SKU used for the Key Vault. The options are: `standard`, `premium`."
  default     = "standard"
}

variable "enabled_for_deployment" {
  description = "Allow Virtual Machines to retrieve certificates stored as secrets from the key vault."
  default     = true
}

variable "enabled_for_disk_encryption" {
  description = "Allow Disk Encryption to retrieve secrets from the vault and unwrap keys."
  default     = true
}

variable "enabled_for_template_deployment" {
  description = "Allow Azure Resource Manager to retrieve secrets from the key vault."
  default     = true
}
variable "public_network_access_enabled" {
  description = "Allow public network access to the key vault for secret retrieval."
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization of data actions"
  default     = false
}

variable "purge_protection_enabled" {
  description = "Is Purge Protection enabled for this Key Vault?"
  default     = false
}



variable "network_acls" {
  description = "Network rules to apply to key vault."
  type = object({
    bypass                     = string
    default_action             = string
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = null
}

variable "private_endpoints" {
  description = "List of private endpoints to create for the Key Vault."
  type = list(object({
    name                 = optional(string, "pep")
    subnet_id            = string
    private_dns_zone_ids = optional(list(string), null)
    subresource_name     = optional(string, "vault")
    resource_group_name  = string
  }))
  default = []
}

variable "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted. The valid value can be between 7 and 90 days"
  default     = 90
}

variable "certificate_contacts" {
  description = "Contact information to send notifications triggered by certificate lifetime events"
  type = list(object({
    email = optional(string, "")
    name  = optional(string, "")
    phone = optional(string, "")
  }))
  default = []
}


variable "access_policies" {
  description = "List of access policies for the Key Vault."
  type = list(object({
    object_ids                       = optional(list(string), [])
    azure_ad_group_names             = optional(list(string), [])
    azure_ad_user_principal_names    = optional(list(string), [])
    azure_ad_service_principal_names = optional(list(string), [])
    certificate_permissions          = optional(list(string), [])
    key_permissions                  = optional(list(string), [])
    secret_permissions               = optional(list(string), [])
    storage_permissions              = optional(list(string), [])
  }))
  default = []
}

variable "rbac_access_policies" {
  description = "List of RBAC access policies for the Key Vault."
  type = list(object({
    object_ids                       = optional(list(string), [])
    azure_ad_group_names             = optional(list(string), [])
    azure_ad_user_principal_names    = optional(list(string), [])
    azure_ad_service_principal_names = optional(list(string), [])
    role_definition_names            = optional(list(string), [])
  }))
  default = []
}


locals {
  access_policies = [
    for p in var.access_policies : merge({
      azure_ad_group_names             = []
      object_ids                       = []
      azure_ad_user_principal_names    = []
      certificate_permissions          = []
      key_permissions                  = []
      secret_permissions               = []
      storage_permissions              = []
      azure_ad_service_principal_names = []
    }, p)
  ]

  azure_ad_group_names             = distinct(flatten(local.access_policies[*].azure_ad_group_names))
  azure_ad_user_principal_names    = distinct(flatten(local.access_policies[*].azure_ad_user_principal_names))
  azure_ad_service_principal_names = distinct(flatten(local.access_policies[*].azure_ad_service_principal_names))

  group_object_ids = { for g in data.azuread_group.adgrp : lower(g.display_name) => g.id }
  user_object_ids  = { for u in data.azuread_user.adusr : lower(u.user_principal_name) => u.id }
  spn_object_ids   = { for s in data.azuread_service_principal.adspn : lower(s.display_name) => s.id }

  flattened_access_policies = concat(
    flatten([
      for p in local.access_policies : flatten([
        for i in p.object_ids : {
          object_id               = i
          certificate_permissions = p.certificate_permissions
          key_permissions         = p.key_permissions
          secret_permissions      = p.secret_permissions
          storage_permissions     = p.storage_permissions
        }
      ])
    ]),
    flatten([
      for p in local.access_policies : flatten([
        for n in p.azure_ad_group_names : {
          object_id               = local.group_object_ids[lower(n)]
          certificate_permissions = p.certificate_permissions
          key_permissions         = p.key_permissions
          secret_permissions      = p.secret_permissions
          storage_permissions     = p.storage_permissions
        }
      ])
    ]),
    flatten([
      for p in local.access_policies : flatten([
        for n in p.azure_ad_user_principal_names : {
          object_id               = local.user_object_ids[lower(n)]
          certificate_permissions = p.certificate_permissions
          key_permissions         = p.key_permissions
          secret_permissions      = p.secret_permissions
          storage_permissions     = p.storage_permissions
        }
      ])
    ]),
    flatten([
      for p in local.access_policies : flatten([
        for n in p.azure_ad_service_principal_names : {
          object_id               = local.spn_object_ids[lower(n)]
          certificate_permissions = p.certificate_permissions
          key_permissions         = p.key_permissions
          secret_permissions      = p.secret_permissions
          storage_permissions     = p.storage_permissions
        }
      ])
    ])
  )

  grouped_access_policies = { for p in local.flattened_access_policies : p.object_id => p... }

  combined_access_policies = [
    for k, v in local.grouped_access_policies : {
      object_id               = k
      certificate_permissions = distinct(flatten(v[*].certificate_permissions))
      key_permissions         = distinct(flatten(v[*].key_permissions))
      secret_permissions      = distinct(flatten(v[*].secret_permissions))
      storage_permissions     = distinct(flatten(v[*].storage_permissions))
    }
  ]

}

output "combined_access_policies" {
  value = local.combined_access_policies
}


locals {
  rbac_access_policies = [
    for p in var.rbac_access_policies : merge({
      azure_ad_group_names             = []
      object_ids                       = []
      azure_ad_user_principal_names    = []
      azure_ad_service_principal_names = []
      role_definition_names            = []
    }, p)
  ]

  rbac_azure_ad_group_names             = distinct(flatten(local.rbac_access_policies[*].azure_ad_group_names))
  rbac_azure_ad_user_principal_names    = distinct(flatten(local.rbac_access_policies[*].azure_ad_user_principal_names))
  rbac_azure_ad_service_principal_names = distinct(flatten(local.rbac_access_policies[*].azure_ad_service_principal_names))

  rbac_group_object_ids = { for g in data.azuread_group.adgrp : lower(g.display_name) => g.id }
  rbac_user_object_ids  = { for u in data.azuread_user.adusr : lower(u.user_principal_name) => u.id }
  rbac_spn_object_ids   = { for s in data.azuread_service_principal.adspn : lower(s.display_name) => s.id }

  rbac_flattened_access_policies = concat(
    flatten([
      for p in local.rbac_access_policies : flatten([
        for i in p.object_ids : {
          object_id             = i
          role_definition_names = p.role_definition_names
        }
      ])
    ]),
    flatten([
      for p in local.rbac_access_policies : flatten([
        for n in p.azure_ad_group_names : {
          object_id             = local.rbac_group_object_ids[lower(n)]
          role_definition_names = p.role_definition_names
        }
      ])
    ]),
    flatten([
      for p in local.rbac_access_policies : flatten([
        for n in p.azure_ad_user_principal_names : {
          object_id             = local.rbac_user_object_ids[lower(n)]
          role_definition_names = p.role_definition_names
        }
      ])
    ]),
    flatten([
      for p in local.rbac_access_policies : flatten([
        for n in p.azure_ad_service_principal_names : {
          object_id             = local.rbac_spn_object_ids[lower(n)]
          role_definition_names = p.role_definition_names
        }
      ])
    ])
  )

  rbac_grouped_access_policies = { for p in local.rbac_flattened_access_policies : p.object_id => p... }

  rbac_combined_access_policies = [
    for k, v in local.rbac_grouped_access_policies : {
      object_id             = k
      role_definition_names = distinct(flatten(v[*].role_definition_names))
    }
  ]

}

