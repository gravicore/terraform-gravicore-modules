variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "PrimarySchedulerAccount" {
  type        = "string"
  default     = ""
  description = "Account number of Instance Scheduler account"
}

variable "is_child" {
  description = "Passes through if account is chid. 1 or 0"
  default     = "0"
}
