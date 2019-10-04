# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "domain_name" {
  type        = string
  description = "A domain name for which the certificate should be issued"
}

variable "zone_id" {
  type        = string
  description = "The ID of the hosted zone to contain acm record."
}

variable "validate_certificate" {
  type        = bool
  default     = true
  description = "Whether to validate certificate by creating Route53 record"
}

variable "validation_allow_overwrite_records" {
  type        = bool
  default     = true
  description = "Whether to allow overwrite of Route53 records"
}

variable "wait_for_validation" {
  type        = bool
  default     = true
  description = "Whether to wait for the validation to complete"
}

variable "subject_alternative_names" {
  type        = list(string)
  default     = []
  description = "A list of domains that should be SANs in the issued certificate"
}

variable "validation_method" {
  type        = string
  default     = "DNS"
  description = "Which method to use for validation. DNS or EMAIL are valid, NONE can be used for certificates that were imported into ACM and then into Terraform."
}

locals {
  domain_name               = join(".", compact(split(".", var.domain_name)))
  subject_alternative_names = distinct(concat(["*.${local.domain_name}"], var.subject_alternative_names))

  // Get distinct list of domains and SANs
  distinct_domain_names = distinct(concat([local.domain_name], [for s in local.subject_alternative_names : replace(s, "*.", "")]))
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_acm_certificate" "acm" {
  count = var.create ? 1 : 0
  tags  = local.tags

  domain_name               = local.domain_name
  subject_alternative_names = local.subject_alternative_names
  validation_method         = var.validation_method
  lifecycle {
    create_before_destroy = true
  }
}

locals {
  // Copy domain_validation_options for the distinct domain names
  validation_domains = [for k, v in aws_acm_certificate.acm[0].domain_validation_options : tomap(v) if contains(local.distinct_domain_names, v.domain_name)]
}

resource "aws_route53_record" "acm_validation" {
  count      = var.create && var.validation_method == "DNS" && var.validate_certificate ? length(local.distinct_domain_names) : 0
  depends_on = [aws_acm_certificate.acm]

  zone_id = var.zone_id
  # name    = element(local.validation_domains, count.index)["resource_record_name"]
  # type    = element(local.validation_domains, count.index)["resource_record_type"]
  name = local.validation_domains[count.index].resource_record_name
  type = local.validation_domains[count.index].resource_record_type
  ttl  = 60
  records = [
    # element(local.validation_domains, count.index)["resource_record_value"]
    local.validation_domains[count.index].resource_record_value
  ]
  allow_overwrite = var.validation_allow_overwrite_records
}

resource "aws_acm_certificate_validation" "acm" {
  count = var.create && var.validation_method == "DNS" && var.validate_certificate && var.wait_for_validation ? 1 : 0

  certificate_arn         = aws_acm_certificate.acm[0].arn
  validation_record_fqdns = aws_route53_record.acm_validation.*.fqdn
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "acm_certificate_arn" {
  description = "The ARN of the certificate"
  value       = element(concat(aws_acm_certificate.acm.*.arn, [""]), 0)
}

output "acm_certificate_domain_validation_options" {
  description = "A list of attributes to feed into other resources to complete certificate validation. Can have more than one element, e.g. if SANs are defined. Only set if DNS-validation was used."
  value       = flatten(aws_acm_certificate.acm.*.domain_validation_options)
}

output "acm_certificate_validation_emails" {
  description = "A list of addresses that received a validation E-Mail. Only set if EMAIL-validation was used."
  value       = flatten(aws_acm_certificate.acm.*.validation_emails)
}

output "acm_validation_route53_record_fqdns" {
  description = "List of FQDNs built using the zone domain and name."
  value       = aws_route53_record.acm_validation.*.fqdn
}

output "acm_distinct_domain_names" {
  description = "List of distinct domains names used for the validation."
  value       = local.distinct_domain_names
}

output "acm_validation_domains" {
  description = "List of distinct domain validation options. acm is useful if subject alternative names contain wildcards."
  value       = local.validation_domains
}
