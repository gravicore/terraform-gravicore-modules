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

variable "dnssec_kms_key_arn" {
  type        = string
  default     = ""
  description = "KMS Key for Route 53 DNSSEC KSK"
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
  count   = var.create ? 1 : 0
  name    = local.sub_domain_name
  tags    = local.tags
  comment = join(" ", tolist([var.desc_prefix, format("VPC Public DNS zone for %s", local.stage_prefix)]))
}

resource "aws_route53_record" "dns_public_ns" {
  count = var.create ? 1 : 0
  name  = aws_route53_zone.dns_public[count.index].name

  allow_overwrite = true
  zone_id         = aws_route53_zone.dns_public[count.index].zone_id
  type            = "NS"
  ttl             = 30

  records = aws_route53_zone.dns_public[0].name_servers
}

resource "aws_route53_record" "dns_public_soa" {
  count = var.create ? 1 : 0
  name  = aws_route53_zone.dns_public[0].name

  allow_overwrite = true
  zone_id         = aws_route53_zone.dns_public[0].zone_id
  type            = "SOA"
  ttl             = 60

  records = [
    "${aws_route53_zone.dns_public[0].name_servers.0}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400",
  ]
}

resource "aws_route53_key_signing_key" "ksk" {
  count                      = (var.create && var.dnssec_create) ? 1 : 0
  hosted_zone_id             = aws_route53_zone.dns_public[0].zone_id
  name                       = local.sub_domain_name
  key_management_service_arn = var.dnssec_kms_key_arn
  status                     = "ACTIVE"
}

resource "aws_route53_hosted_zone_dnssec" "dnssec" {
  count = (var.create && var.dnssec_create) ? 1 : 0
  depends_on = [
    aws_route53_key_signing_key.ksk
  ]
  hosted_zone_id = aws_route53_zone.dns_public[0].zone_id
}

# Private DNS

resource "aws_route53_zone" "dns_private" {
  count = var.create ? 1 : 0
  tags  = local.tags

  name    = local.sub_domain_name
  comment = join(" ", tolist([var.desc_prefix, format("VPC Private DNS zone for %s %s", local.stage_prefix, var.vpc_id)]))

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

output "ds_records" {
  description = "DS records for registrar"
  value       = concat(aws_route53_key_signing_key.ksk.*.ds_record, [""])[0]
}

output "public_ds_key" {
  description = "Public DS records for registrar"
  value       = concat(aws_route53_key_signing_key.ksk.*.public_key, [""])[0]
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
