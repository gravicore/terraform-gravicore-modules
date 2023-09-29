provider "acme" {
  server_url = acme.server_url
}

locals {
  algorithm = "RSA"
  bits      = 2048
}

resource "tls_private_key" "default" {
  count     = var.create ? 1 : 0
  algorithm = local.algorithm
  rsa_bits  = local.bits
}

resource "acme_registration" "default" {
  count           = var.create ? 1 : 0
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.email
}

resource "random_password" "default" {
  count  = var.create ? 1 : 0
  length = 24
}

resource "acme_certificate" "default" {
  count                     = var.create ? 1 : 0
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = var.common_name
  subject_alternative_names = var.subject_alternative_names
  certificate_p12_password  = random_password.cert.result

  dns_challenge {
    provider = "azure"

    config = {
      AZURE_RESOURCE_GROUP = var.dns.zone_rg_name
      AZURE_ZONE_NAME      = var.dns.zone_name
      AZURE_TTL            = 300
    }
  }
}

resource "azurerm_key_vault_certificate" "default" {
  count        = var.create ? 1 : 0
  name         = var.key_vault_certificate_name
  key_vault_id = var.key_vault_id

  certificate {
    contents = acme_certificate.certificate.certificate_p12
    password = acme_certificate.certificate.certificate_p12_password
  }

  certificate_policy {
    issuer_parameters {
      name = "Unknown"
    }

    key_properties {
      key_size   = local.bits
      key_type   = local.algorithm
      exportable = true
      reuse_key  = true
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}

resource "azurerm_key_vault_secret" "default" {
  count        = var.create ? 1 : 0
  name         = "${var.key_vault_certificate_name}-password"
  value        = acme_certificate.certificate.certificate_p12_password
  key_vault_id = var.key_vault_id
}


resource "azurerm_container_app_environment_certificate" "default" {
  count                        = var.container_app_environment_id != null ? 1 : 0
  name                         = var.key_vault_certificate_name
  container_app_environment_id = var.container_app_environment_id
  certificate_blob             = acme_certificate.certificate.certificate_p12
  certificate_password         = acme_certificate.certificate.certificate_p12
}