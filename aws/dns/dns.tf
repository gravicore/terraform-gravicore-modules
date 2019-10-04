# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "parent_domain_name" {}

variable "aws_subdomain_name" {
  default = "aws"
}

variable "parent_domain_name_servers" {
  type        = list(string)
  default     = null
  description = ""
}

variable "delegated_domains" {
  type = list(object({
    name                 = string
    public_name_servers  = list(string)
    private_name_servers = list(string)
  }))
  default     = []
  description = "A list of delegated domains to add to DNS"
}

variable "ttl" {
  type        = number
  default     = 30
  description = "Default TTL for the NS records"
}

locals {
  domain_name     = replace(join(".", compact(list(var.stage, var.parent_domain_name))), "prd.", "")
  aws_domain_name = replace(join(".", compact(list(var.stage, var.aws_subdomain_name, var.parent_domain_name))), "prd.", "")
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Public DNS
# ----------------------------------------------------------------------------------------------------------------------

# Parent public DNS

resource "aws_route53_zone" "dns_public" {
  count   = var.create ? 1 : 0
  name    = local.domain_name
  tags    = local.tags
  comment = join(" ", list(var.desc_prefix, format("Public DNS zone for %s", join(var.delimiter, [var.namespace, var.stage]))))
}

locals {
  public_domain_name_servers = coalesce(var.parent_domain_name_servers, aws_route53_zone.dns_public[0].name_servers)
}

resource "aws_route53_record" "dns_public_ns" {
  count = var.create ? 1 : 0
  name  = aws_route53_zone.dns_public[0].name

  allow_overwrite = true
  zone_id         = aws_route53_zone.dns_public[0].zone_id
  type            = "NS"
  ttl             = var.ttl

  records = local.public_domain_name_servers
}

resource "aws_route53_record" "dns_public_soa" {
  count = var.create ? 1 : 0
  name  = aws_route53_zone.dns_public[0].name

  allow_overwrite = true
  zone_id         = aws_route53_zone.dns_public[0].zone_id
  type            = "SOA"
  ttl             = 60

  records = [
    "${local.public_domain_name_servers[0]}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400",
  ]
}

# AWS DNS

resource "aws_route53_zone" "dns_aws" {
  count   = var.create && var.aws_subdomain_name != "" ? 1 : 0
  name    = local.aws_domain_name
  tags    = local.tags
  comment = join(" ", list(var.desc_prefix, format("AWS Public DNS zone for %s", join(var.delimiter, [var.namespace, var.stage]))))
}

resource "aws_route53_record" "dns_aws_ns" {
  count = var.create && var.aws_subdomain_name != "" ? 1 : 0
  name  = aws_route53_zone.dns_aws[0].name

  allow_overwrite = true
  zone_id         = aws_route53_zone.dns_aws[0].zone_id
  type            = "NS"
  ttl             = var.ttl

  records = aws_route53_zone.dns_aws[0].name_servers
}

resource "aws_route53_record" "dns_aws_soa" {
  count = var.create && var.aws_subdomain_name != "" ? 1 : 0
  name  = aws_route53_zone.dns_aws[0].name

  allow_overwrite = true
  zone_id         = aws_route53_zone.dns_aws[0].zone_id
  type            = "SOA"
  ttl             = 60

  records = [
    "${aws_route53_zone.dns_aws[0].name_servers[0]}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400",
  ]
}

resource "aws_route53_record" "dns_aws_public_ns" {
  count = var.create && var.aws_subdomain_name != "" ? 1 : 0
  name  = aws_route53_zone.dns_aws[0].name

  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "NS"
  ttl     = var.ttl
  records = aws_route53_zone.dns_aws[0].name_servers
}

# Environment/Stage DNS

resource "aws_route53_record" "dns_delegated_public_ns" {
  count = var.create ? length(var.delegated_domains) : 0
  name  = var.delegated_domains[count.index].name

  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "NS"
  ttl     = var.ttl
  records = var.delegated_domains[count.index].public_name_servers
}

# resource "aws_route53_record" "dns_delegated_private_ns" {
#   count = var.create ? length(var.delegated_domains) : 0
#   name  = var.delegated_domains[count.index].name

#   zone_id = aws_route53_zone.dns_private[0].zone_id
#   type    = "NS"
#   ttl     = var.ttl
#   records = var.delegated_domains[count.index].private_name_servers
# }

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# Public Zone

output "dns_public_zone_id" {
  value = aws_route53_zone.dns_public[0].zone_id
}

output "dns_public_zone_name" {
  value = aws_route53_zone.dns_public[0].name
}

output "dns_public_zone_name_servers" {
  value = flatten(aws_route53_zone.dns_public.*.name_servers)
}

# Delegated Zones

# output "dns_delegated_public_zone_id" {
#   value = aws_route53_zone.dns_public[0].zone_id
# }

# output "dns_public_zone_name" {
#   value = aws_route53_zone.dns_public[0].name
# }

# output "dns_public_zone_name_servers" {
#   value = flatten(aws_route53_zone.dns_public.*.name_servers)
# }
