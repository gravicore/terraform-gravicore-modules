# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------


variable "name" {
  type        = string
  default     = "ca"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/ca"
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


variable "container_app_environment_id" {
  type        = string
  default     = ""
  description = "(Required) The ID of the Container App Environment within which this Container App should exist. Changing this forces a new resource to be created."
}

variable "identity_ids" {
  type        = list(string)
  default     = []
  description = "(Optional) The identities to assign to the container app."
}

variable "container_apps" {
  description = "The container apps to deploy."
  nullable    = false
  validation {
    condition     = length(var.container_apps) >= 1
    error_message = "At least one container should be provided."
  }

  type = map(object({
    name          = string
    revision_mode = string
    template = object({
      containers = list(object({
        name    = string
        image   = string
        args    = optional(list(string))
        command = optional(list(string))
        cpu     = string
        memory  = string
        env = optional(list(object({
          name        = string
          secret_name = optional(string)
          value       = optional(string)
        })))
        liveness_probe = optional(object({
          failure_count_threshold = optional(number)
          header = optional(object({
            name  = string
            value = string
          }))
          host             = optional(string)
          initial_delay    = optional(number, 10)
          interval_seconds = optional(number, 10)
          path             = optional(string)
          port             = number
          timeout          = optional(number, 1)
          transport        = string
        }))
        readiness_probe = optional(object({
          failure_count_threshold = optional(number)
          header = optional(object({
            name  = string
            value = string
          }))
          host                    = optional(string)
          interval_seconds        = optional(number, 10)
          path                    = optional(string)
          port                    = number
          success_count_threshold = optional(number, 3)
          timeout                 = optional(number)
          transport               = string
        }))
        startup_probe = optional(object({
          failure_count_threshold = optional(number)
          header = optional(object({
            name  = string
            value = string
          }))
          host             = optional(string)
          interval_seconds = optional(number, 10)
          path             = optional(string)
          port             = number
          timeout          = optional(number)
          transport        = string
        }))
        volume_mounts = optional(object({
          name = string
          path = string
        }))
      }))
      max_replicas    = optional(number)
      min_replicas    = optional(number, 1)
      revision_suffix = optional(string)
      azure_queue_scale_rule = optional(list(object({
        name         = string
        queue_name   = string
        queue_length = number
        authentication = object({
          secret_name       = string
          trigger_parameter = string
        })
      })))
      custom_scale_rule = optional(list(object({
        name             = string
        custom_rule_type = string
        metadata         = any
        authentication = optional(list(object({
          secret_name       = string
          trigger_parameter = string
        })))
      })))
      http_scale_rule = optional(list(object({
        name                = string
        concurrent_requests = number
        authentication = optional(list(object({
          secret_name       = string
          trigger_parameter = string
        })))
      })))
      tcp_scale_rule = optional(list(object({
        name                = string
        concurrent_requests = number
        authentication = optional(list(object({
          secret_name       = string
          trigger_parameter = string
        })))
      })))
      volume = optional(list(object({
        name         = string
        storage_name = optional(string)
        storage_type = optional(string)
      })))
    })
    ingress = optional(object({
      allow_insecure_connections = optional(bool, false)
      external_enabled           = optional(bool, false)
      target_port                = number
      transport                  = optional(string)
      fqdn                       = optional(string)
      custom_domain = optional(list(object({
        name                     = string
        certificate_name         = string
        certificate_binding_type = optional(string)
      })))
      traffic_weight = optional(object({
        label           = optional(string)
        latest_revision = optional(string)
        revision_suffix = optional(string)
        percentage      = number
      }))
    }))

    dapr = optional(object({
      app_id       = string
      app_port     = number
      app_protocol = optional(string)
    }))

    registry = optional(list(object({
      server               = string
      username             = optional(string)
      password_secret_name = optional(string)
      identity             = optional(string)
    })))

    secret = optional(list(object({
      name              = string
      secret_name_in_kv = string
    })), [])

  }))
}

variable "key_vault_id" {
  type        = string
  description = "(Required) The ID of the Key Vault to use for secrets. Changing this forces a new resource to be created."
}

locals {
  secret_keys = merge([
    for app_name, app in var.container_apps : {
      for secret in app.secret : "${app_name}-${secret.name}" => {
        app_name          = app_name
        secret_name       = secret.name
        secret_name_in_kv = secret.secret_name_in_kv
      }
    }
  ]...)

  certificate_names      = [for app in var.container_apps : can([for domain in app.ingress.custom_domain : domain.certificate_name != null ? domain.certificate_name : ""]) ? [for domain in app.ingress.custom_domain : domain.certificate_name != null ? domain.certificate_name : ""] : []]
  flattened_certificates = compact(flatten(local.certificate_names))
}

variable "metric_alerts" {
  description = "List of metric alerts to create"
  type        = any
  default     = {}
}

variable "activity_log_alerts" {
  description = "List of activity log alerts to create"
  type        = any
  default     = {}
}

variable "action_group" {
  description = "Action group to use for alerts"
  type        = any
  default     = {}
}

