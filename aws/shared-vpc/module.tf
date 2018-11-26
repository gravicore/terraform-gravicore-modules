terraform {
  required_version = "~> 0.11.0"

  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

# ----------------------------------------------------------------------------------------------------------------------
# Providers
# ----------------------------------------------------------------------------------------------------------------------

provider "aws" {
  version = "~> 1.42.0"
  region  = "${var.aws_region}"

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/grv_deploy_svc"
  }
}

provider "aws" {
  alias   = "master"
  version = "~> 1.42.0"
  region  = "${var.aws_region}"

  assume_role {
    role_arn = "arn:aws:iam::${var.master_account_id}:role/grv_deploy_svc"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Shared Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "parent_domain_name" {}

variable "aws_subdomain_name" {
  default = "aws"
}

locals {
  dns_zone_name = "${join(".", compact(list(local.vpc_subdomain_name, var.aws_subdomain_name, var.parent_domain_name)))}"
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  default = "vpc"
}

variable "create" {
  default = "true"
}

variable "aws_region" {
  default = "us-east-1"
}

variable terraform_module {
  default = "gravicore/terraform-gravicore-modules/aws/shared-vpc"
}

# ----------------------------------------------------------------------------------------------------------------------
# Platform Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "namespace" {
  default = "grv"
}

variable "environment" {
  default = "shared"
}

variable "stage" {
  default = "dev"
}

variable "repository" {
  default = ""
}

variable "master_account_id" {}
variable "account_id" {}

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
