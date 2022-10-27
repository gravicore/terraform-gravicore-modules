# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = "storage account"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/sa"
  description = "The owner and name of the Terraform module"
}

variable "az_location" {
  type        = string
  default     = "westus"
  description = "The Azure region to deploy module into"
}

variable "create" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources"
}

variable "resource_group_name" {
  type        = string
  default     = ""
  description = ""
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

variable "repository" {
  type        = string
  default     = "sf-dm-infra"
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
  module_prefix      = coalesce(var.module_prefix, join(var.delimiter, compact([local.stage_prefix, var.name])))

  business_tags = {
    namespace          = var.namespace
    environment        = var.environment
    environment_prefix = local.environment_prefix
  }
  technical_tags = {
    stage       = var.stage
    module      = var.name
    repository  = var.repository
    az_location = var.az_location
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

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

# ----------------------------------------------------------------------------------------------------------------------
# Module Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "subnet_id" {
  type        = string
  description = "(Required) The ID of the Subnet where this Network Interface should be located in."
}

variable "private_ip_address_version" {
  type        = string
  default     = "IPv4"
  description = "(Optional) The IP Version to use. Possible values are IPv4 or IPv6. Defaults to IPv4."
}

variable "private_ip_address_allocation" {
  type        = string
  default     = "Dynamic"
  description = "(Required) The allocation method used for the Private IP Address. Possible values are Dynamic and Static."
}

variable "private_ip_address" {
  type        = string
  default     = null
  description = "(Optional) The Static IP Address which should be used. [Only used if private_ip_address_allocation is 'Static']"
}

variable "dns_servers" {
  type        = list(string)
  default     = null
  description = "(Optional) A list of IP Addresses defining the DNS Servers which should be used for this Network Interface."
}

variable "edge_zone" {
  type        = string
  default     = null
  description = "(Optional) Specifies the Edge Zone within the Azure Region where this Network Interface should exist. Changing this forces a new Network Interface to be created."
}

variable "enable_ip_forwarding" {
  type        = bool
  default     = false
  description = "(Optional) Should IP Forwarding be enabled? Defaults to false."
}

variable "enable_accelerated_networking" {
  type        = bool
  default     = false
  description = "(Optional) Should Accelerated Networking be enabled? Defaults to false."
}

variable "internal_dns_name_label" {
  type        = string
  defult      = null
  description = "(Optional) The (relative) DNS Name used for internal communications between Virtual Machines in the same Virtual Network."
}

variable "gateway_load_balancer_frontend_ip_configuration_id" {
  type        = string
  default     = null
  description = "(Optional) The Frontend IP Configuration ID of a Gateway SKU Load Balancer."
}

variable "public_ip_address_id" {
  type        = string
  default     = null
  description = "(Optional) Reference to a Public IP Address to associate with this NIC"
}

variable "primary" {
  type        = bool
  default     = true
  description = "(Optional) Is this the Primary IP Configuration? Must be true for the first ip_configuration when multiple are specified. Defaults to false [overriden to true]."
}

variable "size" {
  type        = string
  default     = "Standard_B2"
  description = "(Required) The SKU which should be used for this Virtual Machine, such as Standard_F2."
}

variable "license_type" {
  type        = string
  default     = null
  description = "(Optional) Specifies the BYOL Type for this Virtual Machine. Possible values are RHEL_BYOS and SLES_BYOS."
}

variable "admin_password" {
  type        = string
  default     = null
  description = "(Optional) The Password which should be used for the local-administrator on this Virtual Machine. Changing this forces a new resource to be created."
}

variable "admin_username" {
  type        = string
  default     = "admin"
  desciprtion = "(Required) The username of the local administrator used for the Virtual Machine. Changing this forces a new resource to be created."
}

variable "assign_public_ip" {
  type        = bool
  default     = false
  description = "Whether or not to assign a public IP address to this NIC"
}

variable "source_image_id" {
  type        = string
  default     = ""
  description = "(Optional) The ID of the Image which this Virtual Machine should be created from. Changing this forces a new resource to be created. Possible Image ID types include Image IDs, Shared Image IDs, Shared Image Version IDs, Community Gallery Image IDs, Community Gallery Image Version IDs, Shared Gallery Image IDs and Shared Gallery Image Version IDs."
}

variable "create_public_ip" {
  type        = bool
  default     = false
  description = "A bool flag to enable the creation of a public ip address"
}

variable "os_disk_caching" {
  type        = string
  default     = "ReadWrite"
  description = "(Required) The Type of Caching which should be used for the Internal OS Disk. Possible values are None, ReadOnly and ReadWrite."
}

variable "os_disk_account_type" {
  type        = string
  default     = "Standard_LRS"
  description = "(Required) The Type of Storage Account which should back this the Internal OS Disk. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS. Changing this forces a new resource to be created."
}

variable "image_publisher" {
  type        = string
  default     = "Canonical"
  description = "(Optional) Specifies the publisher of the image used to create the virtual machines."
}

variable "image_offer" {
  type        = string
  default     = "UbuntuServer"
  description = "(Optional) Specifies the offer of the image used to create the virtual machines."
}

variable "image_sku" {
  type        = string
  default     = "16.04-LTS"
  description = "(Optional) Specifies the SKU of the image used to create the virtual machines."
}

variable "image_version" {
  type        = string
  default     = "latest"
  description = "(Optional) Specifies the version of the image used to create the virtual machines."
}