# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

################################################
#######Variables for Device Configuration#######

variable device_challenge_required_on_new_device {
  type        = bool
  description = "Indicate whether a challenge is required on a new device. Only application to a new device"
  default     = false
}

variable device_only_remembered_on_user_prompt {
  type        = bool
  description = "If a true, a device is only remembered on user prompt (true or false)"
  default     = false
}

