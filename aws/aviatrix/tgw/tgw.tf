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
  type = map(any)
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

resource "aws_ssm_parameter" "tgw_name" {
  for_each    = var.create ? toset(["tgw_name"]) : []
  name        = "/${local.stage_prefix}/${var.name}-name"
  description = "Name of the AWS TGW which is going to be created"
  tags = local.tags

  type   = "String"
  value  = concat(aviatrix_aws_tgw.tgw.*.tgw_name, [""])[0]
  depends_on = [
    aviatrix_aws_tgw.tgw,
  ]
}

resource "aws_ssm_parameter" "tgw_account_name" {
  for_each    = var.create ? toset(["tgw_account_name"]) : []
  name        = "/${local.stage_prefix}/${var.name}-account-name"
  description = "This parameter represents the name of a Cloud-Account in Aviatrix controller"
  tags = local.tags

  type   = "String"
  value  = concat(aviatrix_aws_tgw.tgw.*.account_name, [""])[0]
  depends_on = [
    aviatrix_aws_tgw.tgw,
  ]
}

resource "aws_ssm_parameter" "tgw_region" {
  for_each    = var.create ? toset(["tgw_region"]) : []
  name        = "/${local.stage_prefix}/${var.name}-region"
  description = "The AWS region the TGW is located"
  tags = local.tags

  type   = "String"
  value  = concat(aviatrix_aws_tgw.tgw.*.region, [""])[0]
  depends_on = [
    aviatrix_aws_tgw.tgw,
  ]
}

resource "aws_ssm_parameter" "tgw_asn" {
  for_each    = var.create ? toset(["tgw_asn"]) : []
  name        = "/${local.stage_prefix}/${var.name}-asn"
  description = "BGP Local ASN (Autonomous System Number"
  tags = local.tags

  type   = "String"
  value  = concat(aviatrix_aws_tgw.tgw.*.aws_side_as_number, [""])[0]
  depends_on = [
    aviatrix_aws_tgw.tgw,
  ]
}

resource "aws_ssm_parameter" "tgw_attached_aviatrix_transit_gateways" {
  for_each    = var.create ? toset(["tgw_attached_aviatrix_transit_gateways"]) : []
  name        = "/${local.stage_prefix}/${var.name}-attached-aviatrix-transit-gateways"
  description = "A list of Names of Aviatrix Transit Gateway to attach to one of the three default domains: Aviatrix_Edge_Domain"
  tags = local.tags

  type   = "StringList"
  value  = join(",", concat(aviatrix_aws_tgw.tgw.*.attached_aviatrix_transit_gateway, ["null"])[0])
  depends_on = [
    aviatrix_aws_tgw.tgw,
  ]
}

# Outputs

output "aviatrix_tgw_name" {
  value       = concat(aviatrix_aws_tgw.tgw.*.tgw_name, [""])[0]
  description = "Name of the AWS TGW which is going to be created"
}

output "aviatrix_tgw_account_name" {
  value       = concat(aviatrix_aws_tgw.tgw.*.account_name, [""])[0]
  description = "This parameter represents the name of a Cloud-Account in Aviatrix controller"
}

output "aviatrix_tgw_region" {
  value       = concat(aviatrix_aws_tgw.tgw.*.region, [""])[0]
  description = "The AWS region the TGW is located"
}

output "aviatrix_tgw_asn" {
  value       = concat(aviatrix_aws_tgw.tgw.*.aws_side_as_number, [""])[0]
  description = "BGP Local ASN (Autonomous System Number)"
}

output "aviatrix_tgw_attached_aviatrix_transit_gateways" {
  value       = concat(aviatrix_aws_tgw.tgw.*.attached_aviatrix_transit_gateway, [""])[0]
  description = "A list of Names of Aviatrix Transit Gateway to attach to one of the three default domains: Aviatrix_Edge_Domain"
}

output "aviatrix_tgw_security_domains" {
  value       = concat(aviatrix_aws_tgw.tgw.*.security_domains, [""])[0]
  description = "Security Domains created together with AWS TGW's creation"
}