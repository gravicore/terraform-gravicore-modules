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
    "Aviatrix_Edge_Domain" = { connected_domains = [
      "Shared_Service_Domain",
      "dev",
      "stg",
      "prd"
    ] },
    "Shared_Service_Domain" = { connected_domains = [
      "Aviatrix_Edge_Domain",
      "dev",
      "stg",
      "prd"
    ] },
    "Default_Domain" = { connected_domains = [] },
    "dev" = { connected_domains = [
      "Aviatrix_Edge_Domain",
      "Shared_Service_Domain",
      "stg"
    ] },
    "stg" = { connected_domains = [
      "Aviatrix_Edge_Domain",
      "Shared_Service_Domain",
      "dev"
    ] },
    "prd" = { connected_domains = [
      "Aviatrix_Edge_Domain",
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
    }
  }

  #   security_domains {
  #     security_domain_name = "SDN1"
  #     connected_domains = [
  #       "Aviatrix_Edge_Domain"
  #     ]
  #     attached_vpc {
  #       vpc_account_name = "devops1"
  #       vpc_id           = "vpc-0e2fac2b91"
  #       vpc_region       = "us-east-1"
  #     }
  #     attached_vpc {
  #       vpc_account_name = "devops1"
  #       vpc_id           = "vpc-0c63660a16"
  #       vpc_region       = "us-east-1"
  #     }
  #     attached_vpc {
  #       vpc_account_name = local.stage_prefix
  #       vpc_id           = "vpc-032005cc371"
  #       vpc_region       = "us-east-1"
  #     }
  #   }

  #   security_domains {
  #     security_domain_name = "mysdn2"
  #     attached_vpc {
  #       vpc_region       = "us-east-1"
  #       vpc_account_name = local.stage_prefix
  #       vpc_id           = "vpc-032005cc371"
  #     }
  #   }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "tgw_name" {
  value       = aviatrix_aws_tgw.tgw[0].tgw_name
  description = "Name of the AWS TGW which is going to be created"
}

output "tgw_account_name" {
  value       = aviatrix_aws_tgw.tgw[0].account_name
  description = "This parameter represents the name of a Cloud-Account in Aviatrix controller"
}

output "tgw_region" {
  value       = aviatrix_aws_tgw.tgw[0].region
  description = "The AWS region the TGW is located"
}

output "tgw_asn" {
  value       = aviatrix_aws_tgw.tgw[0].aws_side_as_number
  description = "BGP Local ASN (Autonomous System Number)"
}

output "tgw_attached_aviatrix_transit_gateways" {
  value       = aviatrix_aws_tgw.tgw[0].attached_aviatrix_transit_gateway
  description = "A list of Names of Aviatrix Transit Gateway to attach to one of the three default domains: Aviatrix_Edge_Domain"
}

output "tgw_security_domains" {
  value       = aviatrix_aws_tgw.tgw[0].security_domains
  description = "Security Domains created together with AWS TGW's creation"
}