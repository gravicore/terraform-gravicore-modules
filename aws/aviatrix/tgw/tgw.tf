# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "attached_aviatrix_transit_gateways" {
  type        = list(string)
  default     = []
  description = ""
}

variable "aws_side_as_number" {
  type        = number
  default     = 64512
  description = ""
}

variable "manage_vpc_attachment" {
  type        = string
  default     = false
  description = "This parameter is a switch used to allow attaching VPCs to tgw using the aviatrix_aws_tgw resource. If it is set to false, attachment of vpc must be done using the aviatrix_aws_tgw_vpc_attachment resource."
}

variable "security_domains" {
  type = map
  default = {
    "Default_Domain" = { connected_domains = [
      "Aviatrix_Firewall_Domain",
      "Aviatrix_Edge_Domain",
      "Shared_Service_Domain",
      "dev",
      "stg",
      "prd"
    ] },
    "Shared_Service_Domain" = { connected_domains = [
      "Aviatrix_Firewall_Domain",
      "Aviatrix_Edge_Domain",
      "Default_Domain",
      "dev",
      "stg",
      "prd"
    ] },
    "Aviatrix_Edge_Domain" = { connected_domains = [
      "Aviatrix_Firewall_Domain",
      "Default_Domain",
      "Shared_Service_Domain",
      "dev",
      "stg",
      "prd"
    ] },
    "Aviatrix_Firewall_Domain" = { connected_domains = [
      "Aviatrix_Edge_Domain",
      "Default_Domain",
      "Shared_Service_Domain",
      "prd"
    ] },
    "dev" = { connected_domains = [
      "Aviatrix_Edge_Domain",
      "Default_Domain",
      "Shared_Service_Domain",
    ] },
    "stg" = { connected_domains = [
      "Aviatrix_Edge_Domain",
      "Default_Domain",
      "Shared_Service_Domain",
    ] },
    "prd" = { connected_domains = [
      "Aviatrix_Firewall_Domain",
      "Aviatrix_Edge_Domain",
      "Default_Domain",
      "Shared_Service_Domain",
    ] },
  }
  description = "Map of the security domains associated with the AWS TGW"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Create an Aviatrix AWS TGW 
resource "aviatrix_aws_tgw" "tgw" {
  count        = var.create ? 1 : 0
  tgw_name     = local.stage_prefix
  account_name = local.stage_prefix
  region       = var.aws_region

  aws_side_as_number    = var.aws_side_as_number
  manage_vpc_attachment = var.manage_vpc_attachment

  attached_aviatrix_transit_gateway = coalesce(var.attached_aviatrix_transit_gateways, [
    "${local.module_prefix}-gw1",
    "${local.module_prefix}-gw2"
  ])

  dynamic "security_domains" {
    for_each = var.security_domains
    content {
      security_domain_name = security_domains.key
      connected_domains    = security_domains.value.connected_domains
      aviatrix_firewall    = security_domains.key == "Aviatrix_Firewall_Domain" ? true : false
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# SSM Parameters

module "parameters_tgw" {
  source      = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/parameters?ref=0.20.0"
  providers   = { aws = "aws" }
  create      = var.create && var.create_parameters
  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags

  write_parameters = {
    "/${local.stage_prefix}/${var.name}-name" = { value = aviatrix_aws_tgw.tgw[0].tgw_name,
    description = "Name of the AWS TGW which is going to be created" }
    "/${local.stage_prefix}/${var.name}-account-name" = { value = aviatrix_aws_tgw.tgw[0].account_name,
    description = "This parameter represents the name of a Cloud-Account in Aviatrix controller" }
    "/${local.stage_prefix}/${var.name}-region" = { value = aviatrix_aws_tgw.tgw[0].region,
    description = "The AWS region the TGW is located" }
    "/${local.stage_prefix}/${var.name}-asn" = { value = aviatrix_aws_tgw.tgw[0].aws_side_as_number,
    description = "BGP Local ASN (Autonomous System Number" }
    "/${local.stage_prefix}/${var.name}-attached-aviatrix-transit-gateways" = { value = join(",", aviatrix_aws_tgw.tgw[0].attached_aviatrix_transit_gateway), type = "StringList"
    description = "A list of Names of Aviatrix Transit Gateway to attach to one of the three default domains: Aviatrix_Edge_Domain" }
    "/${local.stage_prefix}/${var.name}-security-domains" = { value = jsonencode(aviatrix_aws_tgw.tgw[0].security_domains),
    description = "Security Domains created together with AWS TGW's creation" }
  }
}

# Outputs

output "aviatrix_tgw_name" {
  value       = aviatrix_aws_tgw.tgw[0].tgw_name
  description = "Name of the AWS TGW which is going to be created"
}

output "aviatrix_tgw_account_name" {
  value       = aviatrix_aws_tgw.tgw[0].account_name
  description = "This parameter represents the name of a Cloud-Account in Aviatrix controller"
}

output "aviatrix_tgw_region" {
  value       = aviatrix_aws_tgw.tgw[0].region
  description = "The AWS region the TGW is located"
}

output "aviatrix_tgw_asn" {
  value       = aviatrix_aws_tgw.tgw[0].aws_side_as_number
  description = "BGP Local ASN (Autonomous System Number)"
}

output "aviatrix_tgw_attached_aviatrix_transit_gateways" {
  value       = aviatrix_aws_tgw.tgw[0].attached_aviatrix_transit_gateway
  description = "A list of Names of Aviatrix Transit Gateway to attach to one of the three default domains: Aviatrix_Edge_Domain"
}

output "aviatrix_tgw_security_domains" {
  value       = aviatrix_aws_tgw.tgw[0].security_domains
  description = "Security Domains created together with AWS TGW's creation"
}