output "certificate_url" {
  value = acme_certificate.default.certificate_url
}

output "certificate_domain" {
  value = acme_certificate.default.certificate_domain
}

output "certificate_not_after" {
  value = acme_certificate.default.certificate_not_after
}
