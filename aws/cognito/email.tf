# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

##############################################
#######Variable for Email Configuration#######

variable email_from_email_address {
  type        = string
  description = "The FROM email address"
  default     = null
}

variable email_reply_to_email_address {
  type        = string
  description = "The REPLY-TO email address"
  default     = null
}

variable email_source_arn {
  type        = string
  description = "The ARN of the email source"
  default     = null
}

variable email_sending_account {
  type        = string
  default     = null
  description = "Instruct Cognito to either use its built-in functional or Amazon SES to send out emails"
}
