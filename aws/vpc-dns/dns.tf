# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  description = "The ID of the VPC"
}

variable "parent_domain_name" {}

variable "aws_subdomain_name" {
  default = "aws"
}

variable "environment_subdomain_name" {
  default = ""
}

locals {
  parent_domain_name         = join(".", compact([var.aws_subdomain_name, var.parent_domain_name]))
  environment_subdomain_name = coalesce(var.environment_subdomain_name, var.environment)
  stage_sub_domain_name      = replace(join("-", compact([var.stage, local.environment_subdomain_name])), "prd-", "")
  sub_domain_name            = "${local.stage_sub_domain_name}.${local.parent_domain_name}"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Public DNS

resource "aws_route53_zone" "dns_public" {
  count   = "${var.create ? 1 : 0}"
  name    = local.sub_domain_name
  tags    = local.tags
  comment = join(" ", list(var.desc_prefix, format("VPC Public DNS zone for %s", local.stage_prefix)))
}

resource "aws_route53_record" "dns_public_ns" {
  count = "${var.create ? 1 : 0}"
  name  = aws_route53_zone.dns_public[count.index].name

  allow_overwrite = true
  zone_id         = aws_route53_zone.dns_public[count.index].zone_id
  type            = "NS"
  ttl             = 30

  records = aws_route53_zone.dns_public[0].name_servers
}

resource "aws_route53_record" "dns_public_soa" {
  count = "${var.create ? 1 : 0}"
  name  = aws_route53_zone.dns_public[0].name

  allow_overwrite = true
  zone_id         = aws_route53_zone.dns_public[0].zone_id
  type            = "SOA"
  ttl             = 60

  records = [
    "${aws_route53_zone.dns_public[0].name_servers.0}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400",
  ]
}

# Private DNS

resource "aws_route53_zone" "dns_private" {
  count = "${var.create ? 1 : 0}"
  tags  = local.tags

  name    = local.sub_domain_name
  comment = join(" ", list(var.desc_prefix, format("VPC Private DNS zone for %s %s", local.stage_prefix, var.vpc_id)))

  vpc {
    vpc_id = var.vpc_id
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "dns_vpc_id" {
  value = var.vpc_id
}

# Public Zone

output "dns_public_zone_id" {
  value = join("", aws_route53_zone.dns_public.*.zone_id)
}

output "dns_public_zone_name" {
  value = join("", aws_route53_zone.dns_public.*.name)
}

output "dns_public_zone_name_servers" {
  value = flatten(aws_route53_zone.dns_public.*.name_servers)
}

# Private Zone

output "dns_private_zone_id" {
  value = join("", aws_route53_zone.dns_private.*.zone_id)
}

output "dns_private_zone_name" {
  value = join("", aws_route53_zone.dns_private.*.name)
}

output "dns_private_zone_name_servers" {
  value = flatten(aws_route53_zone.dns_private.*.name_servers)
}
