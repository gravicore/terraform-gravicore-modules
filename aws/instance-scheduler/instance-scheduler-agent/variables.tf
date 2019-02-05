variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "master_account_id" {
  type        = "string"
  default     = ""
  description = "Account number containing the parent Instance Scheduler"
}

variable "create" {}
