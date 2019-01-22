variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "master_account_id" {
  type        = "string"
  default     = ""
  description = "Account number containing the parent Instance Scheduler"
}

variable "is_child" {
  description = "Passes through if account is child. 1 or 0"
  default     = "0"
}

variable "create" {}
