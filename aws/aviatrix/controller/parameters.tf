# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "parameter_store_kms_arn" {
  type        = "string"
  default     = "alias/parameter_store_key"
  description = "The ARN of a KMS key used to encrypt and decrypt SecretString values"
}

data "aws_kms_key" "parameter_store_key" {
  key_id = "alias/parameter_store_key"
}
