terraform {
  required_version = "~> 0.11.2"

  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

# ----------------------------------------------------------------------------------------------------------------------
# Providers
# ----------------------------------------------------------------------------------------------------------------------

provider "aws" {
  version = "~> 1.58.0"
  region  = "${var.aws_region}"

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/${var.account_assume_role_name}"
  }
}

provider "aws" {
  alias   = "master"
  version = "~> 1.58.0"
  region  = "${var.aws_region}"

  assume_role {
    role_arn = "arn:aws:iam::${var.master_account_id}:role/${var.master_account_assume_role_name}"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Shared Variables
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  default = "elasticache-redis"
}

variable "create" {
  default = "true"
}

variable "aws_region" {
  default = "us-east-1"
}

variable terraform_module {
  default = "gravicore/terraform-gravicore-modules/aws/elasticache-redis"
}

# ----------------------------------------------------------------------------------------------------------------------
# Platform Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "namespace" {
  default = "grv"
}

variable "environment" {}

variable "stage" {
  default = "dev"
}

variable "repository" {
  default = ""
}

variable "master_account_id" {}
variable "account_id" {}

variable "master_account_assume_role_name" {
  default = "grv_deploy_svc"
}

variable "account_assume_role_name" {
  default = "OrganizationAccountAccessRole"
}

variable "desc_prefix" {
  default = "Gravicore Module:"
}

variable "tags" {
  default = {}
}

locals {
  environment_prefix = "${join("-", list(var.namespace, var.environment))}"
  stage_prefix       = "${join("-", list(var.namespace, var.environment, var.stage))}"
  module_prefix      = "${join("-", list(var.namespace, var.environment, var.stage, var.name))}"

  business_tags = {
    Namespace   = "${var.namespace}"
    Environment = "${var.environment}"
  }

  technical_tags = {
    Stage           = "${var.stage}"
    Repository      = "${var.repository}"
    MasterAccountID = "${var.master_account_id}"
    AccountID       = "${var.account_id}"
    TerraformModule = "${var.terraform_module}"
  }

  automation_tags = {}

  security_tags = {}

  tags = "${merge(
    local.business_tags,
    local.technical_tags,
    local.automation_tags,
    local.security_tags,
    var.tags
  )}"
}
