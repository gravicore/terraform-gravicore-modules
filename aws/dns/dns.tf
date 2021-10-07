# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable parent_domain_name {}

variable aws_subdomain_name {
  default = "aws"
}

variable parent_domain_name_servers {
  type        = list(string)
  default     = null
  description = ""
}

variable delegated_domains {
  type = list(object({
    name                 = string
    public_name_servers  = list(string)
    private_name_servers = list(string)
  }))
  default     = []
  description = "A list of delegated domains to add to DNS"
}

variable ttl_default_ns {
  type        = number
  default     = 30
  description = "Default TTL for the NS records"
}

variable ttl_default_soa {
  type        = number
  default     = 60
  description = "Default TTL for the SOA records"
}

variable zone_force_destroy {
  type        = bool
  default     = false
  description = "(Optional) Whether to destroy all records (possibly managed outside of Terraform) in the zone when destroying the zone"
}

locals {
  domain_name     = replace(join(".", compact(list(var.stage, var.parent_domain_name))), "prd.", "")
  aws_domain_name = replace(join(".", compact(list(var.stage, var.aws_subdomain_name, var.parent_domain_name))), "prd.", "")
}

variable records_a {
  type        = map(any)
  default     = {}
  description = "Provides a Route53 A record resource"
}

variable records_aaaa {
  type        = map(any)
  default     = {}
  description = "Provides a Route53 A record resource"
}

variable records_caa {
  type        = map(any)
  default     = {}
  description = "Provides a Route53 A record resource"
}

variable records_cname {
  type        = map(any)
  default     = {}
  description = "Provides a Route53 A record resource"
}

variable records_ds {
  type        = map(any)
  default     = {}
  description = "Provides a Route53 A record resource"
}

variable records_mx {
  type        = map(any)
  default     = {}
  description = "Provides a Route53 A record resource"
}

variable records_naptr {
  type        = map(any)
  default     = {}
  description = "Provides a Route53 A record resource"
}

variable records_ptr {
  type        = map(any)
  default     = {}
  description = "Provides a Route53 A record resource"
}

variable records_spf {
  type        = map(any)
  default     = {}
  description = "Provides a Route53 A record resource"
}

variable records_srv {
  type        = map(any)
  default     = {}
  description = "Provides a Route53 A record resource"
}

variable records_txt {
  type        = map(any)
  default     = {}
  description = "Provides a Route53 A record resource"
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
  comment = join(" ", list(var.desc_prefix, format("Public DNS zone for %s", local.domain_name)))

  force_destroy = var.zone_force_destroy
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
  ttl             = var.ttl_default_ns

  records = local.public_domain_name_servers
}

resource "aws_route53_record" "dns_public_soa" {
  count = var.create ? 1 : 0
  name  = aws_route53_zone.dns_public[0].name

  allow_overwrite = true
  zone_id         = aws_route53_zone.dns_public[0].zone_id
  type            = "SOA"
  ttl             = var.ttl_default_soa

  records = [
    "${local.public_domain_name_servers[0]}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400",
  ]
}

resource "aws_route53_record" "dns_public_a" {
  for_each = var.create ? var.records_a : {}
  name    = each.key
  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "A"
  ttl     = lookup(each.value, "ttl", 300)
  records = each.value.records

  allow_overwrite = lookup(each.value, "allow_overwrite", true)
}

resource "aws_route53_record" "dns_public_aaaa" {
  for_each = var.create ? var.records_aaaa : {}
  name    = each.key
  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "AAAA"
  ttl     = lookup(each.value, "ttl", 300)
  records = each.value.records

  allow_overwrite = lookup(each.value, "allow_overwrite", true)
}

resource "aws_route53_record" "dns_public_caa" {
  for_each = var.create ? var.records_caa : {}
  name    = each.key
  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "CAA"
  ttl     = lookup(each.value, "ttl", 300)
  records = each.value.records

  allow_overwrite = lookup(each.value, "allow_overwrite", true)
}

resource "aws_route53_record" "dns_public_cname" {
  for_each = var.create ? var.records_cname : {}
  name    = each.key
  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "CNAME"
  ttl     = lookup(each.value, "ttl", 300)
  records = each.value.records

  allow_overwrite = lookup(each.value, "allow_overwrite", true)
}

resource "aws_route53_record" "dns_public_ds" {
  for_each = var.create ? var.records_ds : {}
  name    = each.key
  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "DS"
  ttl     = lookup(each.value, "ttl", 300)
  records = each.value.records

  allow_overwrite = lookup(each.value, "allow_overwrite", true)
}

resource "aws_route53_record" "dns_public_mx" {
  for_each = var.create ? var.records_mx : {}
  name    = each.key
  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "MX"
  ttl     = lookup(each.value, "ttl", 300)
  records = each.value.records

  allow_overwrite = lookup(each.value, "allow_overwrite", true)
}

resource "aws_route53_record" "dns_public_naptr" {
  for_each = var.create ? var.records_naptr : {}
  name    = each.key
  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "NAPTR"
  ttl     = lookup(each.value, "ttl", 300)
  records = each.value.records

  allow_overwrite = lookup(each.value, "allow_overwrite", true)
}

resource "aws_route53_record" "dns_public_ptr" {
  for_each = var.create ? var.records_ptr : {}
  name    = each.key
  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "PTR"
  ttl     = lookup(each.value, "ttl", 300)
  records = each.value.records

  allow_overwrite = lookup(each.value, "allow_overwrite", true)
}

resource "aws_route53_record" "dns_public_spf" {
  for_each = var.create ? var.records_spf : {}
  name    = each.key
  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "SPF"
  ttl     = lookup(each.value, "ttl", 300)
  records = each.value.records

  allow_overwrite = lookup(each.value, "allow_overwrite", true)
}

resource "aws_route53_record" "dns_public_srv" {
  for_each = var.create ? var.records_srv : {}
  name    = each.key
  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "SRV"
  ttl     = lookup(each.value, "ttl", 300)
  records = each.value.records

  allow_overwrite = lookup(each.value, "allow_overwrite", true)
}

resource "aws_route53_record" "dns_public_txt" {
  for_each = var.create ? var.records_txt : {}
  name    = each.key
  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "TXT"
  ttl     = lookup(each.value, "ttl", 300)
  records = each.value.records

  allow_overwrite = lookup(each.value, "allow_overwrite", true)
}

# AWS DNS

resource "aws_route53_zone" "dns_aws" {
  count   = var.create && var.aws_subdomain_name != "" ? 1 : 0
  name    = local.aws_domain_name
  tags    = local.tags
  comment = join(" ", list(var.desc_prefix, format("AWS Public DNS zone for %s", local.aws_domain_name)))

  force_destroy = var.zone_force_destroy
}

resource "aws_route53_record" "dns_aws_ns" {
  count = var.create && var.aws_subdomain_name != "" ? 1 : 0
  name  = aws_route53_zone.dns_aws[0].name

  allow_overwrite = true
  zone_id         = aws_route53_zone.dns_aws[0].zone_id
  type            = "NS"
  ttl             = var.ttl_default_ns

  records = aws_route53_zone.dns_aws[0].name_servers
}

resource "aws_route53_record" "dns_aws_soa" {
  count = var.create && var.aws_subdomain_name != "" ? 1 : 0
  name  = aws_route53_zone.dns_aws[0].name

  allow_overwrite = true
  zone_id         = aws_route53_zone.dns_aws[0].zone_id
  type            = "SOA"
  ttl             = var.ttl_default_soa

  records = [
    "${aws_route53_zone.dns_aws[0].name_servers[0]}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400",
  ]
}

resource "aws_route53_record" "dns_aws_public_ns" {
  count = var.create && var.aws_subdomain_name != "" ? 1 : 0
  name  = aws_route53_zone.dns_aws[0].name

  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "NS"
  ttl     = var.ttl_default_ns
  records = aws_route53_zone.dns_aws[0].name_servers
}

# Environment/Stage DNS

resource "aws_route53_record" "dns_delegated_public_ns" {
  count = var.create ? length(var.delegated_domains) : 0
  name  = var.delegated_domains[count.index].name

  zone_id = aws_route53_zone.dns_public[0].zone_id
  type    = "NS"
  ttl     = var.ttl_default_ns
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

output dns_public_zone_id {
  value = aws_route53_zone.dns_public[0].zone_id
}

output dns_public_zone_name {
  value = aws_route53_zone.dns_public[0].name
}

output dns_public_zone_name_servers {
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
