# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "tgw_vpcs" {
  type        = map(any)
  default     = {}
  description = "A map of VPCs to attach to the TGW"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aviatrix_aws_tgw_vpc_attachment" "tgw_vpcs" {
  for_each = { for vpc_id, vpc in var.tgw_vpcs : vpc_id => vpc if vpc.enabled }

  tgw_name             = concat(aviatrix_aws_tgw.tgw.*.tgw_name, [""])[0]
  region               = var.aws_region
  vpc_id               = each.key
  vpc_account_name     = each.value.vpc_account_name
  security_domain_name = each.value.security_domain_name
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "tgw_vpcs" {
  value       = aviatrix_aws_tgw_vpc_attachment.tgw_vpcs
  description = ""
}
