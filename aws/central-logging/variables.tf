# ----------------------------------------------------------------------------------------------------------------------
# Platform Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "tags" {
  default = {}
}

variable "name" {
  default     = "central-logging"
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

variable "environment" {
  description = "Environment (e.g. `master`)"
  type        = "string"
}

variable "repository" {
  default = ""
}

variable terraform_module {
  default = "gravicore/terraform-gravicore-modules/aws/central-logging"
}

variable "master_account_id" {}
variable "account_id" {}
