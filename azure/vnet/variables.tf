# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------
variable "name" {
  type        = string
  default     = "vnet"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/vnet"
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
  default     = "Gravicore:"
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

variable "vnet_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "(Required) The address space that is used the virtual network. You can supply more than one address space."
}

variable "dns_servers" {
  type        = list(any)
  default     = null
  description = "(Optional) List of IP addresses of DNS servers"
}

variable "edge_zone" {
  type        = string
  default     = null
  description = "(Optional) Specifies the Edge Zone within the Azure Region where this Virtual Network should exist. Changing this forces a new Virtual Network to be created."
}

variable "flow_timeout_in_minutes" {
  type        = number
  default     = null
  description = "(Optional) The flow timeout in minutes for the Virtual Network, which is used to enable connection tracking for intra-VM flows. Possible values are between 4 and 30 minutes."
}

variable "ddos_protection_plan" {
  description = "DDoS protection plan settings"
  type        = any
  default     = null
}

variable "bgp_community" {
  type        = string
  default     = null
  description = "(Optional) The BGP community attribute in format <as-number>:<community-value>."
}


# ----------------------------------------------------------------------------------------------------------------------
# Subnet Variables
# ----------------------------------------------------------------------------------------------------------------------
variable "subnets" {
  type = map(object({
    prefix            = string
    address_newbits   = number
    address_netnum    = number
    service_endpoints = optional(list(string))
    delegation = optional(object({
      name = optional(string)
      service_delegation = optional(object({
        name    = optional(string)
        actions = optional(list(string))
      }), null)
    }), null)
    private_link_service_network_policies_enabled = optional(bool, true)
    private_endpoint_network_policies_enabled     = optional(bool, true)
    nsg_rules = optional(object({
      deny_all_inbound                  = optional(bool, false)
      http_inbound_allowed              = optional(bool, false)
      https_inbound_allowed             = optional(bool, false)
      ssh_inbound_allowed               = optional(bool, false)
      rdp_inbound_allowed               = optional(bool, false)
      winrm_inbound_allowed             = optional(bool, false)
      application_gateway_rules_enabled = optional(bool, false)
      load_balancer_rules_enabled       = optional(bool, false)
      nfs_inbound_allowed               = optional(bool, false)
      cifs_inbound_allowed              = optional(bool, false)
      psql_inbound_allowed              = optional(bool, false)
      allowed_http_sources              = optional(list(string))
      allowed_https_sources             = optional(list(string))
      allowed_ssh_sources               = optional(list(string))
      allowed_rdp_sources               = optional(list(string))
      allowed_winrm_sources             = optional(list(string))
      allowed_nfs_sources               = optional(list(string))
      allowed_cifs_sources              = optional(list(string))
      allowed_psql_sources              = optional(list(string))      
      custom_security_rules = optional(list(object({
        name                         = optional(string)
        access                       = optional(string)
        direction                    = optional(string)
        priority                     = optional(number)
        protocol                     = optional(string)
        source_port_range            = optional(string)
        destination_port_range       = optional(string)
        source_address_prefix        = optional(string)
        destination_address_prefix   = optional(string)
        source_address_prefixes      = optional(list(string))
        destination_address_prefixes = optional(list(string))
      })), [])
    }), null)
  }))
  default     = null
  description = "The subnet information to be created in this VNET"
}



locals {
  subnets_map = { for key, subnet in var.subnets : key => {
    prefix                                        = subnet.prefix
    address_newbits                               = subnet.address_newbits
    address_netnum                                = subnet.address_netnum
    address_prefixes                              = cidrsubnet(var.vnet_cidr_block, subnet.address_newbits, subnet.address_netnum)
    service_endpoints                             = subnet.service_endpoints
    delegation                                    = subnet.delegation
    private_link_service_network_policies_enabled = subnet.private_link_service_network_policies_enabled
    private_endpoint_network_policies_enabled     = subnet.private_endpoint_network_policies_enabled
    nsg_rules = try(subnet.nsg_rules, {
      deny_all_inbound                  = false
      http_inbound_allowed              = false
      https_inbound_allowed             = false
      ssh_inbound_allowed               = false
      rdp_inbound_allowed               = false
      winrm_inbound_allowed             = false
      application_gateway_rules_enabled = false
      load_balancer_rules_enabled       = false
      nfs_inbound_allowed               = false
      cifs_inbound_allowed              = false
      allowed_http_sources              = null
      allowed_https_sources             = null
      allowed_ssh_sources               = null
      allowed_rdp_sources               = null
      allowed_winrm_sources             = null
      allowed_nfs_sources               = null
      allowed_cifs_sources              = null
      custom_security_rules             = []
    })
  } }

  subnets_with_nsg_rules = { for key, value in local.subnets_map : key => value if value.nsg_rules != null }

}

