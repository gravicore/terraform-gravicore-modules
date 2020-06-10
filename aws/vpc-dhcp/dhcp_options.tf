# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "domain_name" {
  description = ""
  type        = string
}

variable "dns_ip_addresses" {
  description = ""
  type        = list(string)
}

variable "netbios_node_type" {
  description = ""
  type        = number
  default     = 2
}

variable "vpc_id" {
  description = "ID of the VPC to associate the DHCP option set"
  type        = string
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_vpc_dhcp_options" "ds" {
  count = var.create ? 1 : 0
  tags  = merge(local.tags, { Name = local.module_prefix })

  domain_name          = var.domain_name
  domain_name_servers  = var.dns_ip_addresses
  ntp_servers          = var.dns_ip_addresses
  netbios_name_servers = var.dns_ip_addresses
  netbios_node_type    = var.netbios_node_type
}

resource "aws_vpc_dhcp_options_association" "ds" {
  count = var.create ? 1 : 0

  vpc_id          = var.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.ds[0].id
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "ds_dhcp_options_id" {
  description = "The ID of the DHCP Options Set."
  value       = aws_vpc_dhcp_options.ds[0].id
}

# output "ds_dhcp_options_domain_name" {
#   description = "The suffix domain name to use by default when resolving non Fully Qualified Domain Names. In other words, this is what ends up being the search value in the /etc/resolv.conf file."
#   value       = aws_directory_service_directory.ds[0].name
# }

# output "ds_dhcp_options_domain_name_servers" {
#   description = "List of name servers to configure in /etc/resolv.conf. If you want to use the default AWS nameservers you should set this to AmazonProvidedDNS."
#   value       = flatten(aws_directory_service_directory.ds[0].dns_ip_addresses)
# }

# output "ds_dhcp_options_ntp_servers" {
#   description = "List of NTP servers to configure."
#   value       = flatten(aws_directory_service_directory.ds[0].dns_ip_addresses)
# }

# output "ds_dhcp_options_netbios_name_servers" {
#   description = "List of NETBIOS name servers."
#   value       = flatten(aws_directory_service_directory.ds[0].dns_ip_addresses)
# }

output "ds_dhcp_options_netbios_node_type" {
  description = "The NetBIOS node type (1, 2, 4, or 8). AWS recommends to specify 2 since broadcast and multicast are not supported in their network. For more information about these node types, see RFC 2132."
  value       = var.netbios_node_type
}

output "vpc_dhcp_options_association_id" {
  description = "The ID of the DHCP Options Set Association."
  value       = aws_vpc_dhcp_options_association.ds[0].id
}
