# ----------------------------------------------------------------------------------------------------------------------
# Platform Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "accounts" {
  default = []
}

variable "allow_gravicore_access" {
  description = "Flag to establish SAML connectivity for Gravicore managed services"
  default     = false
}

variable "iam_account_alias" {
  description = "The account alias to create."
  default     = ""
}
