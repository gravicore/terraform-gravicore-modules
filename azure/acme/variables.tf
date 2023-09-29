# ----------------------------------------------------------------------------------------------------------------------
# Module Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/acme"
  description = "The owner and name of the Terraform module"
}

variable "create" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources"
}

variable "email" {
  type        = string
  description = "Email address for Let's Encrypt registration and recovery contact."
}

variable "common_name" {
  type        = string
  description = "The common name for the certificate."
}

variable "subject_alternative_names" {
  type        = list(string)
  description = "A list of subject alternative names (SANs) for the certificate."
  default     = null
}

variable "key_vault_id" {
  type        = string
  description = "The ID of the Key Vault to store the certificate in."
}

variable "key_vault_certificate_name" {
  type        = string
  description = "The name of the Key Vault certificate."
}

variable "dns" {
  type = object({
    zone_rg_name = string
    zone_name    = string
  })
  description = "DNS configuration for the certificate."
}

variable "acme" {
  type = object({
    server_url = string
  })
  description = "ACME configuration for the certificate."
  default = {
    server_url = "https://acme-v02.api.letsencrypt.org/directory"
  }
}