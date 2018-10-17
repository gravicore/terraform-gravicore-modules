variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "PrimarySchedulerAccount" {
  type        = "string"
  default     = ""
  description = "Account number of Insttance Scheduler account"
}
