# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  type        = string
  description = "VPC ID to deploy the Aviatrisx Gateway into"
}

variable "vpc_subnet_cidr_blocks" {
  type        = list(string)
  description = "List of subnets CIDR blocks to deploy the Aviatrix Gateway into"
}

variable "max_vpn_conn" {
  type        = number
  default     = 253
  description = "Maximum number of active VPN users allowed to be connected to this gateway. Required if vpn_access is true. Make sure the number is smaller than the VPN CIDR block"
}

variable "gw_size" {
  type        = string
  default     = "t2.micro"
  description = "Size of the gateway instance"
}

variable "peering_ha_gw_size" {
  type        = string
  default     = ""
  description = "Size of the Peering HA Gateway"
}

variable "enable_peering_ha" {
  type        = bool
  default     = false
  description = "Enable Peering HA on Aviatrix Gateway"
}

variable "single_az_ha" {
  type        = bool
  default     = true
  description = "Enabled Single AZ HA"
}

variable "vpn_cidr" {
  type        = string
  description = "VPN CIDR block for the container"
}

variable "split_tunnel" {
  type        = bool
  default     = false
  description = "Specify split tunnel mode"
}

variable "dns_zone_id" {
  type        = string
  default     = ""
  description = ""
}

variable "dns_zone_name" {
  type        = string
  default     = ""
  description = ""
}

locals {
  peering_ha_gw_size = coalesce(var.peering_ha_gw_size, var.gw_size)
  enable_peering_ha  = var.enable_peering_ha && length(var.vpc_subnet_cidr_blocks) > 1 ? true : false
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Create an Aviatrix AWS Gateway
resource "aviatrix_gateway" "avx_vpn_gw" {
  count    = var.create ? 1 : 0
  tag_list = compact(distinct([for tag, value in local.tags : format("%s:%s", tag, value)]))

  gw_name      = local.module_prefix
  account_name = local.stage_prefix
  cloud_type   = 1

  gw_size = var.gw_size
  vpc_reg = var.aws_region
  vpc_id  = var.vpc_id
  subnet  = var.vpc_subnet_cidr_blocks[0]

  peering_ha_gw_size = local.enable_peering_ha ? local.peering_ha_gw_size : null
  peering_ha_subnet  = local.enable_peering_ha ? var.vpc_subnet_cidr_blocks[1] : null
  single_az_ha       = var.single_az_ha

  vpn_access   = true
  vpn_cidr     = var.vpn_cidr
  max_vpn_conn = var.max_vpn_conn
  #   enable_vpc_dns_server = true

  split_tunnel = var.split_tunnel
  # client certificate sharing = enabled
  # modify vpn configuration
  # name = idle timeout
  # status = enabled
  # value = 3600 (seconds)
  # modify authentication = SAML
  # duplicate connections status = enabled
  # VPN NAT statue = enabled
}

resource "aws_route53_record" "avx_vpn_gw" {
  count = var.create && var.dns_zone_id != "" && var.dns_zone_name != "" ? 1 : 0
  name  = "vpn.${var.dns_zone_name}"

  zone_id = var.dns_zone_id
  type    = "A"
  ttl     = "30"
  records = distinct(compact([aviatrix_gateway.avx_vpn_gw[0].public_ip, aviatrix_gateway.avx_vpn_gw[0].backup_public_ip]))
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# SSM Parameters

module "parameters_vpn" {
  source      = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/parameters?ref=0.20.0"
  providers   = { aws = "aws" }
  create      = var.create && var.create_parameters
  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags

  write_parameters = {
    "/${local.stage_prefix}/${var.name}-public-ip" = { value = aviatrix_gateway.avx_vpn_gw[0].public_ip,
    description = "Public IP address of the Gateway created" }
    "/${local.stage_prefix}/${var.name}-backup-public-ip" = { value = aviatrix_gateway.avx_vpn_gw[0].backup_public_ip,
    description = "Private IP address of the Gateway created" }
    "/${local.stage_prefix}/${var.name}-public-dns-server" = { value = aviatrix_gateway.avx_vpn_gw[0].public_dns_server,
    description = "DNS server used by the gateway. Default is `8.8.8.8`, can be overridden with the VPC's setting." }
    "/${local.stage_prefix}/${var.name}-security-group-id" = { value = aviatrix_gateway.avx_vpn_gw[0].security_group_id,
    description = "Security group used for the gateway" }
    "/${local.stage_prefix}/${var.name}-instance-id" = { value = aviatrix_gateway.avx_vpn_gw[0].cloud_instance_id
    description = "Instance ID of the gateway" }
    "/${local.stage_prefix}/${var.name}-backup-instance-id" = { value = aviatrix_gateway.avx_vpn_gw[0].cloudn_bkup_gateway_inst_id
    description = "Instance ID of the backup gateway" }
    "/${local.stage_prefix}/${var.name}-dns-name" = { value = aws_route53_record.avx_vpn_gw[0].name,
    description = "DNS name of the Aviatrix VPN Gateway" }
    "/${local.stage_prefix}/${var.name}-dns-fqdn" = { value = aws_route53_record.avx_vpn_gw[0].fqdn
    description = "FQDN built using the zone domain and name" }
  }
}

# Outputs

output "aviatrix_vpn_public_ip" {
  value       = aviatrix_gateway.avx_vpn_gw[0].public_ip
  description = "Public IP address of the Gateway created"
}

output "aviatrix_vpn_backup_public_ip" {
  value       = aviatrix_gateway.avx_vpn_gw[0].backup_public_ip
  description = "Private IP address of the Gateway created"
}

output "aviatrix_vpn_public_dns_server" {
  value       = aviatrix_gateway.avx_vpn_gw[0].public_dns_server
  description = "DNS server used by the gateway. Default is `8.8.8.8`, can be overridden with the VPC's setting."
}

output "aviatrix_vpn_security_group_id" {
  value       = aviatrix_gateway.avx_vpn_gw[0].security_group_id
  description = "Security group used for the gateway"
}

output "aviatrix_vpn_instance_id" {
  value       = aviatrix_gateway.avx_vpn_gw[0].cloud_instance_id
  description = "Instance ID of the gateway"
}

output "aviatrix_vpn_backup_instance_id" {
  value       = aviatrix_gateway.avx_vpn_gw[0].cloudn_bkup_gateway_inst_id
  description = "Instance ID of the backup gateway"
}

output "aviatrix_vpn_dns_name" {
  value       = aws_route53_record.avx_vpn_gw[0].name
  description = "DNS name of the Aviatrix VPN Gateway"
}

output "aviatrix_vpn_dns_fqdn" {
  value       = aws_route53_record.avx_vpn_gw[0].fqdn
  description = "FQDN built using the zone domain and name"
}
