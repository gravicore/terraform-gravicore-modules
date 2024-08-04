# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------
variable "name" {
  type        = string
  default     = "st"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/st"
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

variable "storage_accounts" {
  type = map(object({
    prefix                            = optional(string)
    account_replication_type          = optional(string, "GRS")
    account_tier                      = optional(string, "Standard")
    location                          = optional(string)
    name                              = optional(string)
    resource_group_name               = optional(string)
    access_tier                       = optional(string)
    account_kind                      = optional(string, "StorageV2")
    allow_nested_items_to_be_public   = optional(bool)
    allowed_copy_scope                = optional(string)
    cross_tenant_replication_enabled  = optional(bool)
    default_to_oauth_authentication   = optional(bool)
    edge_zone                         = optional(string)
    enable_https_traffic_only         = optional(bool)
    infrastructure_encryption_enabled = optional(bool)
    is_hns_enabled                    = optional(bool)
    large_file_share_enabled          = optional(bool)
    min_tls_version                   = optional(string)
    nfsv3_enabled                     = optional(bool)
    public_network_access_enabled     = optional(bool)
    queue_encryption_key_type         = optional(string)
    sftp_enabled                      = optional(bool)
    shared_access_key_enabled         = optional(bool)
    table_encryption_key_type         = optional(string)
    tags                              = optional(map(string))

    azure_files_authentication = optional(object({
      directory_type = optional(string)
      active_directory = optional(object({
        domain_guid         = optional(string)
        domain_name         = optional(string)
        domain_sid          = optional(string)
        forest_name         = optional(string)
        netbios_domain_name = optional(string)
        storage_sid         = optional(string)
      }))
    }))

    blob_properties = optional(object({
      change_feed_enabled           = optional(bool)
      change_feed_retention_in_days = optional(number)
      default_service_version       = optional(string)
      last_access_time_enabled      = optional(bool)
      versioning_enabled            = optional(bool, true)
      container_delete_retention_policy = optional(object({
        days = optional(number)
      }))
      delete_retention_policy = optional(object({
        days = optional(number)
      }))
      restore_policy = optional(object({
        days = optional(number)
      }))
      cors_rule = optional(list(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = optional(number)
      })))
    }))

    custom_domain = optional(object({
      name          = optional(string)
      use_subdomain = optional(bool)
    }))

    identity = optional(object({
      type         = optional(string)
      identity_ids = optional(list(string))
    }))

    immutability_policy = optional(object({
      allow_protected_append_writes = optional(bool)
      period_since_creation_in_days = optional(number)
      state                         = optional(string)
    }))

    queue_properties = optional(object({
      cors_rule = optional(list(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = optional(number)
      })))
      hour_metrics = optional(object({
        enabled               = optional(bool)
        version               = optional(string)
        include_apis          = optional(bool)
        retention_policy_days = optional(number)
      }))
      logging = optional(object({
        delete                = optional(bool)
        read                  = optional(bool)
        version               = optional(string)
        write                 = optional(bool)
        retention_policy_days = optional(number)
      }))
      minute_metrics = optional(object({
        enabled               = optional(bool)
        version               = optional(string)
        include_apis          = optional(bool)
        retention_policy_days = optional(number)
      }))
    }))

    routing = optional(object({
      choice                           = optional(string)
      publish_numberernet_endponumbers = optional(bool)
      publish_microsoft_endponumbers   = optional(bool)
    }))

    sas_policy = optional(object({
      expiration_period = optional(string)
      expiration_action = optional(string)
    }))

    share_properties = optional(object({
      cors_rule = optional(list(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = optional(number)
      })))
      retention_policy = optional(object({
        days = optional(number)
      }))
      smb = optional(object({
        authentication_types            = optional(list(string))
        channel_encryption_type         = optional(string)
        kerberos_ticket_encryption_type = optional(string)
        multichannel_enabled            = optional(bool)
        versions                        = optional(list(string))
      }))
    }))

    static_website = optional(object({
      error_404_document = optional(string)
      index_document     = optional(string)
    }))

    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
      }
    ))
    network_rules = optional(object({
      default_action            = optional(string, "Allow")
      bypass                    = optional(list(string), ["AzureServices", "Metrics", "Logging"])
      ip_rules                  = optional(list(string))
      access_allowed_subnet_ids = optional(list(string))
      private_endpoints = optional(list(object({
        private_endpoint_subnet_id = optional(string)
        private_dns_zone_ids       = optional(list(string))
        subresource_name           = optional(string)
      })))
      timeouts = optional(object({
        create = optional(string)
        delete = optional(string)
        read   = optional(string)
        update = optional(string)
      }))
    }))

    storage_containers = optional(list(object({
      name                  = optional(string)
      container_access_type = optional(string)
      metadata              = optional(map(string))
      timeouts = optional(object({
        create = optional(string)
        delete = optional(string)
        read   = optional(string)
        update = optional(string)
      }))
    })))
    storage_share = optional(list(object({
      name             = optional(string)
      quota            = optional(number)
      access_tier      = optional(string)
      enabled_protocol = optional(string)
      metadata         = optional(map(string))
      acl              = optional(list(map(string)))
      timeouts = optional(object({
        create = optional(string)
        delete = optional(string)
        read   = optional(string)
        update = optional(string)
      }))
    })))
  }))
  default = {}
  validation {
    condition     = alltrue([for st in var.storage_accounts : length(st.prefix) <= 5 || st.prefix == null])
    error_message = "The prefix must be 5 characters or fewer."
  }
}

variable "logs_destinations_ids" {
  type        = list(string)
  default     = []
  description = "List of destination resources IDs for logs diagnostic destination."
}
