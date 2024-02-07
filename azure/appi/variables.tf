# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = "appi"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/appi"
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

variable "key_vault_id" {
  type        = string
  description = "The ID of the Azure Key Vault"

}
variable "application_insights" {
  type = map(object({
    name                                  = string
    application_type                      = string
    daily_data_cap_in_gb                  = optional(number)
    retention_in_days                     = optional(string)
    daily_data_cap_notifications_disabled = optional(bool)
    sampling_percentage                   = optional(number)
    disable_ip_masking                    = optional(bool)
    workspace_id                          = optional(string)
    local_authentication_disabled         = optional(bool)
    internet_ingestion_enabled            = optional(bool)
    internet_query_enabled                = optional(bool)
    force_customer_storage_for_profiler   = optional(bool)
  }))
  default = {}
}



locals {
  smart_detector_alert_rules = {
    "dependency_latency_degradation" = {
      name          = "Dependency Latency Degradation"
      detector_type = "DependencyPerformanceDegradationDetector"
      description   = "Dependency Latency Degradation notifies you of an unusual increase in response by a dependency your app is calling (e.g. REST API or database)"
      severity      = "Sev3"
      frequency     = "P1D"
    }

    "exception_anomalies" = {
      name          = "Exception Anomalies"
      detector_type = "ExceptionVolumeChangedDetector"
      description   = "Exception Anomalies notifies you of an unusual rise in the rate of exceptions thrown by your app."
      severity      = "Sev3"
      frequency     = "P1D"
    }

    "failure_anomalies" = {
      name          = "Failure Anomalies"
      detector_type = "FailureAnomaliesDetector"
      description   = "Failure Anomalies notifies you of an unusual rise in the rate of failed HTTP requests or dependency calls."
      severity      = "Sev3"
      frequency     = "PT1M"
    }

    "potential_memory_leak" = {
      name          = "Potential Memory Leak"
      detector_type = "MemoryLeakDetector"
      description   = "Potential Memory Leak notifies you of increased memory consumption pattern by your app which may indicate a potential memory leak."
      severity      = "Sev3"
      frequency     = "P1D"
    }

    "response_latency_degradation" = {
      name          = "Response Latency Degradation"
      detector_type = "RequestPerformanceDegradationDetector"
      description   = "Response Latency Degradation notifies you of an unusual increase in latency in your app response to requests."
      severity      = "Sev3"
      frequency     = "P1D"
    }

    "trace_severity_degradation" = {
      name          = "Trace Severity Degradation"
      detector_type = "TraceSeverityDetector"
      description   = "Trace Severity Degradation notifies you of an unusual increase in the severity of the traces generated by your app."
      severity      = "Sev3"
      frequency     = "P1D"
    }
  }
}



variable "webtests" {
  description = "Configuration for Azure Application Insights Web Tests"
  type = map(object({
    enabled   = bool
    frequency = optional(number, 300)
    kind      = optional(string, "standard")
    locations = list(object({
      Id = string
    }))
    name = string
    request = object({
      follow_redirects = optional(bool, true)
      headers = optional(list(object({
        key   = string
        value = string
      })), [])
      http_verb                = optional(string, "GET")
      parse_dependent_requests = optional(bool, false)
      request_body             = optional(string)
      request_url              = string
    })
    retry_enabled        = optional(bool, true)
    synthetic_monitor_id = optional(string)
    timeout              = optional(number, 30)
    validation_rules = optional(object({
      content_validation = optional(object({
        content_match      = string
        ignore_case        = optional(bool, false)
        pass_if_text_found = optional(bool, true)
      }))
      expected_http_status_code         = optional(number)
      ignore_http_status_code           = optional(bool, false)
      ssl_cert_remaining_lifetime_check = optional(number)
      ssl_check                         = optional(bool, false)
    }))
  }))
}

