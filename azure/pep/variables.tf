# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------
variable "name" {
  type        = string
  default     = "pep"
  description = "The name of the main module which call the this module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/pep"
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
  description = "Namespace, which could be your organization abbreviation, client name, etc. (e.g. gravicore 'grv', HashiCorp 'hc')"
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
  subnet_prefix      = element(split("-", element(split("/", var.subnet_id), length(split("/", var.subnet_id)) - 1)), 5)
  module_prefix      = coalesce(var.module_prefix, join(var.delimiter, compact([local.stage_prefix, var.application, module.azure_region.location_short, var.name, "${local.subnet_prefix}snet", var.name])))

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


variable "ip_configurations" {
  description = <<EOD
List of IP Configuration object. Any modification to the parameters of the IP Configuration object forces a new resource to be created.
```
name               = Name of the IP Configuration.
member_name        = Member name of the IP Configuration. If it is not specified, it will use the value of `subresource_name`. Only valid if `target_resource` is not a Private Link Service.
subresource_name   = Subresource name of the IP Configuration. Only valid if `target_resource` is not a Private Link Service.
private_ip_address = Private IP address within the Subnet of the Private Endpoint.
```
EOD
  type = list(object({
    name               = optional(string, "default")
    member_name        = optional(string)
    subresource_name   = optional(string)
    private_ip_address = string
  }))
  default  = []
  nullable = false
}

variable "is_manual_connection" {
  description = "Does the Private Endpoint require manual approval from the remote resource owner? Default to `false`."
  type        = bool
  default     = false
}

variable "request_message" {
  description = "A message passed to the owner of the remote resource when the Private Endpoint attempts to establish the connection to the remote resource. Only valid if `is_manual_connection` is set to `true`."
  type        = string
  default     = "Private Endpoint Deployment"
}

variable "target_resource" {
  description = "Private Link Service Alias or ID of the target resource."
  type        = string

  validation {
    condition     = length(regexall("^([a-z0-9\\-]+)\\.([a-z0-9\\-]+)\\.([a-z]+)\\.(azure)\\.(privatelinkservice)$", var.target_resource)) == 1 || length(regexall("^\\/(subscriptions)\\/([a-z0-9\\-]+)\\/(resourceGroups)\\/([A-Za-z0-9\\-_]+)\\/(providers)\\/([A-Za-z\\.]+)\\/([A-Za-z]+)\\/([A-Za-z0-9\\-]+)", var.target_resource)) == 1
    error_message = "The `target_resource` variable must be a Private Link Service Alias or a resource ID."
  }
}

variable "subresource_name" {
  description = "Name of the subresource corresponding to the target Azure resource. Only valid if `target_resource` is not a Private Link Service."
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "The resource ID of the subnet for the private endpoint"
  type        = string
  default     = ""
}

variable "private_dns_zone_ids" {
  description = "Private DNS Zone which a new record will be created for the Private Endpoint. Only valid if `use_existing_private_dns_zones` is set to `true` and `target_resource` is not a Private Link Service. One of `private_dns_zones_ids` or `private_dns_zones_names` must be specified."
  type        = list(string)
  default     = null
}

locals {
  resource_alias              = length(regexall("^([a-z0-9\\-]+)\\.([a-z0-9\\-]+)\\.([a-z]+)\\.(azure)\\.(privatelinkservice)$", var.target_resource)) == 1 ? var.target_resource : null
  resource_id                 = length(regexall("^\\/(subscriptions)\\/([a-z0-9\\-]+)\\/(resourceGroups)\\/([A-Za-z0-9\\-_]+)\\/(providers)\\/([A-Za-z\\.]+)\\/([A-Za-z]+)\\/([A-Za-z0-9\\-]+)", var.target_resource)) == 1 ? var.target_resource : null
  is_not_private_link_service = local.resource_alias == null && !contains(try(split("/", local.resource_id), []), "privateLinkServices")

  private_dns_zone_group_name     = local.is_not_private_link_service ? join(var.delimiter, [local.module_prefix, var.az_region, "pdnszg"]) : null
  private_service_connection_name = join(var.delimiter, [local.module_prefix, var.az_region, "psc"])
}

