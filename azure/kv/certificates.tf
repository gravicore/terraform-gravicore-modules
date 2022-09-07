# resource "azurerm_key_vault_certificate" "cert" {
#   count        = var.create ? 1 : 0
#   name         = join(var.delimiter, [local.stage_prefix, "kv", "cert"])
#   key_vault_id = concat(azurerm_key_vault.default.*.id, [""])[0]
#   tags         = local.tags

#   certificate_policy {
#     issuer_parameters {
#       name = var.certificate_issuer
#     }

#     key_properties {
#       exportable = var.certificate_exportable
#       key_size   = var.certificate_key_size
#       key_type   = var.certificate_key_type
#       reuse_key  = var.certificate_reuse_key
#     }

#     lifetime_action {
#       action {
#         action_type = var.certificate_lifetime_action
#       }

#       trigger {
#         days_before_expiry = var.certificate_lifetime_trigger
#       }
#     }

#     secret_properties {
#       content_type = var.certificate_content_type
#     }

#     x509_certificate_properties {
#       # Server Authentication = 1.3.6.1.5.5.7.3.1
#       # Client Authentication = 1.3.6.1.5.5.7.3.2
#       extended_key_usage = ["1.3.6.1.5.5.7.3.1"] #?

#       key_usage = [
#         "cRLSign",
#         "dataEncipherment",
#         "digitalSignature",
#         "keyAgreement",
#         "keyCertSign",
#         "keyEncipherment",
#       ]

#       subject_alternative_names {
#         dns_names = ["internal.contoso.com", "domain.hello.world"]
#       }

#       subject            = "CN=hello-world"
#       validity_in_months = 12
#     }
#   }
# }
