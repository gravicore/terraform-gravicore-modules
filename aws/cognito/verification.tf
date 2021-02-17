# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

#########################################################
#######Variables for Verification Message Template#######

variable verification_default_email_option {
  type        = string
  default     = "CONFIRM_WITH_CODE"
  description = "The default email option. Must be either CONFIRM_WITH_CODE or CONFIRM_WITH_LINK. Default to CONFIRM_WITH_CODE"
}

variable verification_email_message {
  type        = string
  default     = null
  description = "The email message template. Must contain the {####} placeholder. Conflicts with email_verification_message argument"
}

variable verification_email_message_by_link {
  type        = string
  default     = null
  description = "The email message template for sending a confirmation link to the user, it must contain the {##Click Here##} placeholder."
}

variable verification_email_subject {
  type        = string
  default     = null
  description = "The subject line for the email message template. Conflicts with email_verification_subject argument"
}

variable verification_email_subject_by_link {
  type        = string
  default     = null
  description = "The subject line for the email message template for sending a confirmation link to the user."
}

variable verification_sms_message {
  type        = string
  default     = null
  description = "The SMS message template. Must contain the {####} placeholder. Conflicts with sms_verification_message argument"
}
