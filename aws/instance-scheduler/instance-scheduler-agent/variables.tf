variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "master_account_id" {
  type        = string
  default     = ""
  description = "Account number containing the parent Instance Scheduler"
}

variable "create" {
}

variable "enable_kms_access" {
  type        = bool
  default     = true
  description = "Value to enable or disable KMS access in the remote IS role"
}

