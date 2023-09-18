# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = "agw"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/agw"
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

variable "sku_capacity" {
  description = "The Capacity of the SKU to use for this Application Gateway - which must be between 1 and 10, optional if autoscale_configuration is set"
  type        = number
  default     = 2
}

variable "sku" {
  description = "The Name of the SKU to use for this Application Gateway. Possible values are Standard_v2 and WAF_v2."
  type        = string
  default     = "WAF_v2"
}

variable "zones" {
  description = "A collection of availability zones to spread the Application Gateway over. This option is only supported for v2 SKUs"
  type        = list(number)
  default     = [1, 2, 3]
}

variable "firewall_policy_id" {
  description = "ID of a Web Application Firewall Policy"
  type        = string
  default     = null
}

variable "enable_http2" {
  description = "Whether to enable http2 or not"
  type        = bool
  default     = true
}

variable "public_ip_address_id" {
  description = "The ID of a Public IP Address which the Application Gateway should use. The allocation method for the Public IP Address depends on the sku of this Application Gateway."
  type        = string
  default     = ""
}

variable "frontend_port_settings" {
  description = "Frontend port settings. Each port setting contains the name and the port for the frontend port."
  type = list(object({
    name = string
    port = number
  }))
}


### Security

variable "ssl_policy" {
  description = "Application Gateway SSL configuration. The list of available policies can be found here: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#disabled_protocols"
  type = object({
    disabled_protocols   = optional(list(string), [])
    policy_type          = optional(string, "Predefined")
    policy_name          = optional(string, "AppGwSslPolicy20170401S")
    cipher_suites        = optional(list(string), [])
    min_protocol_version = optional(string, "TLSv1_2")
  })
  default = null
}

variable "ssl_profile" {
  description = "Application Gateway SSL profile. Default profile is used when this variable is set to null. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#name"
  type = list(object({
    name                             = optional(string)
    trusted_client_certificate_names = optional(list(string), [])
    verify_client_cert_issuer_dn     = optional(bool, false)
    ssl_policy = optional(object({
      disabled_protocols   = optional(list(string), [])
      policy_type          = optional(string, "Predefined")
      policy_name          = optional(string, "AppGwSslPolicy20170401S")
      cipher_suites        = optional(list(string), [])
      min_protocol_version = optional(string, "TLSv1_2")
    }))
  }))
  default = null
}

variable "trusted_root_certificate_configs" {
  description = "List of trusted root certificates. `file_path` is checked first, using `data` (base64 cert content) if null. This parameter is required if you are not using a trusted certificate authority (eg. selfsigned certificate)."
  type = list(object({
    name                = string
    data                = optional(string)
    file_path           = optional(string)
    key_vault_secret_id = optional(string)
  }))
  default = []
}


variable "custom_error_configuration" {
  description = "List of objects with global level custom error configurations."
  type = list(object({
    status_code           = string
    custom_error_page_url = string
  }))
  default = []
}

variable "ssl_certificates_configs" {
  description = "List of objects with SSL certificates configurations."
  type = list(object({
    name                = string
    data                = optional(string)
    password            = optional(string)
    key_vault_secret_id = optional(string)
  }))
  default = []
}

variable "authentication_certificates_configs" {
  description = "List of objects with authentication certificates configurations."
  type = list(object({
    name = string
    data = string
  }))
  default = []
}

variable "trusted_client_certificates_configs" {
  description = "List of objects with trusted client certificates configurations."
  type = list(object({
    name = string
    data = string
  }))
  default = []
}

variable "force_firewall_policy_association" {
  description = "Enable if the Firewall Policy is associated with the Application Gateway."
  type        = bool
  default     = false
}

variable "waf_configuration" {
  description = "WAF configuration object (only available with WAF_v2 SKU) with following attribute."
  type = object({
    enabled                  = optional(bool, true)
    file_upload_limit_mb     = optional(number, 100)
    firewall_mode            = optional(string, "Prevention")
    max_request_body_size_kb = optional(number, 128)
    request_body_check       = optional(bool, true)
    rule_set_type            = optional(string, "OWASP")
    rule_set_version         = optional(string, 3.1)
    disabled_rule_group = optional(list(object({
      rule_group_name = string
      rules           = optional(list(string))
    })), [])
    exclusion = optional(list(object({
      match_variable          = string
      selector                = optional(string)
      selector_match_operator = optional(string)
    })), [])
  })
  default = {}
}

### IDENTITY
variable "user_assigned_identity_id" {
  description = "User assigned identity id assigned to this resource."
  type        = string
  default     = null
}

### APPGW PRIVATE
variable "private" {
  description = "Boolean variable to create a private Application Gateway. When `true`, the default http listener will listen on private IP instead of the public IP."
  type        = bool
  default     = false
}

variable "private_ip" {
  description = "Private IP for Application Gateway. Used when variable `private` is set to `true`."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Custom subnet ID for attaching the Application Gateway."
  type        = string
  nullable    = false
  default     = ""
}

### Autoscaling
variable "autoscaling_parameters" {
  description = "Map containing autoscaling parameters. Must contain at least min_capacity"
  type = object({
    min_capacity = number
    max_capacity = optional(number, 5)
  })
  default = null
}

### Backend, listener, probe, and rule variable

variable "backends" {
  default = {}
  type = map(object({
    prefix = string

    backend_pool = object({
      fqdns        = optional(list(string))
      ip_addresses = optional(list(string))
    })

    backend_http_settings = object({
      port                                = number
      protocol                            = string
      cookie_based_affinity               = string
      request_timeout                     = optional(number)
      host_name                           = optional(string)
      pick_host_name_from_backend_address = optional(bool)
      path                                = optional(string)
      probe_name                          = optional(string)
      authentication_certificate = optional(object({
        name = string
        id   = string
      }))
      connection_draining = optional(object({
        enabled = bool
        timeout = number
      }))
    })

    http_listeners = object({
      frontend_port_name   = string
      protocol             = string
      host_name            = optional(string)
      host_names           = optional(list(string))
      require_sni          = optional(bool)
      ssl_certificate_name = optional(string)
      firewall_policy_id   = optional(string)
      ssl_profile_name     = optional(string)
      custom_error_configurations = optional(list(object({
        custom_error_page_url = string
        status_code           = string
      })))
    })


    redirect_configuration = optional(object({
      redirect_type        = string
      target_url           = string
      target_listener_name = optional(string)
      include_path         = optional(bool)
      include_query_string = optional(bool)
    }))


    rewrite_rule_set = optional(object({
      rewrite_rules = optional(list(object({
        name          = string
        rule_sequence = string

        conditions = optional(list(object({
          variable    = string
          pattern     = string
          ignore_case = optional(bool, false)
          negate      = optional(bool, false)
        })), [])

        response_header_configurations = optional(list(object({
          header_name  = string
          header_value = string
        })), [])

        request_header_configurations = optional(list(object({
          header_name  = string
          header_value = string
        })), [])

        url_reroute = optional(object({
          path         = optional(string)
          query_string = optional(string)
          components   = optional(string)
          reroute      = optional(bool)
        }))
      })))
    }))


    url_path_map = optional(object({
      use_redirect = bool
      path_rules = list(object({
        name  = string
        paths = list(string)
      }))
    }))

    request_routing_rule = object({
      rule_type    = string
      use_redirect = bool
      priority     = optional(number)
      use_rewrite  = bool
    })


    probes = optional(object({
      interval                                  = number
      path                                      = string
      protocol                                  = string
      timeout                                   = number
      unhealthy_threshold                       = number
      minimum_servers                           = optional(number)
      host                                      = optional(string)
      port                                      = optional(number)
      pick_host_name_from_backend_http_settings = optional(bool)
      match = optional(object({
        body        = optional(string)
        status_code = optional(list(string))
      }))
    }))
  }))
}

