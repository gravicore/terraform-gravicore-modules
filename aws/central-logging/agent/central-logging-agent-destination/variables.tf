variable "namespace" {
  description = "Namespace (e.g. `cp` or `cloudposse`)"
  type        = "string"
}

variable "stage" {
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
  type        = "string"
}

variable "environment" {
  description = "Environment (e.g. `master`)"
  type        = "string"
}

variable "repository" {
  type = "string"
}

variable "master_account_id" {}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "retention_in_days" {
  description = "Number of days you want to retain log events in the log group"
  default     = "30"
}

variable "filter_pattern" {
  description = "Valid CloudWatch Logs filter pattern for subscribing to a filtered stream of log events"
  default     = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action, flowlogstatus]"
}

variable "enabled" {
  default     = "true"
  description = "Set to false to prevent the module from creating anything"
}

variable "account_id" {
  description = "Account number of the current account"
  default     = ""
}

variable "log_type" {
  description = "Type of log. IE flow_log"
}
