variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "attributes" {
  type        = "list"
  default     = []
  description = "Additional attributes (e.g. `policy` or `role`)"
}

variable "delimiter" {
  type        = "string"
  default     = "-"
  description = "Delimiter to be used between `name`, `namespace`, `stage`, etc."
}

variable "name" {
  default     = ""
  description = "Name  (e.g. `bastion` or `db`)"
}

variable "namespace" {
  description = "Namespace (e.g. `cp` or `cloudposse`)"
  type        = "string"
}

variable "stage" {
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
  type        = "string"
}

variable "test" {
  type        = "string"
  default     = "-"
  description = "derp"
}

variable "child_account" {
  type        = "map"
  default     = {}
  description = "Child accounts to create destination points for"
}

variable "s3_log_Location" {
  type        = "string"
  description = "S3 location for the logs streamed to this destination; example marketing/prod/999999999999/flow-logs/"
}
