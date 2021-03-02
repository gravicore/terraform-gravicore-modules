# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

##########################################
#######Variable for Password Policy#######

variable minimum_length {
  type        = number
  description = "The minimum length of the password policy that you have set"
  default     = 8
}

variable require_lowercase {
  type        = bool
  description = "Whether you have required users to use at least one lowercase letter in their password"
  default     = true
}

variable require_numbers {
  type        = bool
  description = "Whether you have required users to use at least one number in their password"
  default     = true
}

variable require_symbols {
  type        = bool
  description = "Whether you have required users to use at least on symbol in their password"
  default     = true
}

variable require_uppercase {
  type        = bool
  description = "Whether you have required users to use at least one uppercase letter in their password"
  default     = true
}

variable temporary_password_validity_days {
  type        = number
  description = "The user account expiration limit, in days, after which the account is no longer usable"
  default     = 7
}
