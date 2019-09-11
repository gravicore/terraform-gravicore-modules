terraform {
  required_version = "~> 0.11.8"

  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

provider "aws" {
  version = "~> 2.26.0"
  region  = "${var.aws_region}"

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/${var.account_assume_role_name}"
  }
}

provider "aws" {
  alias   = "master"
  version = "~> 2.26.0"
  region  = "${var.aws_region}"

  assume_role {
    role_arn = "arn:aws:iam::${var.master_account_id}:role/${var.master_account_assume_role_name}"
  }
}

locals {
  is_master = "${var.master_account_id == var.account_id ? 1 : 0 }"
  is_child  = "${var.master_account_id != var.account_id ? 1 : 0 }"

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
    local.technical_tags,
    local.business_tags,
    local.automation_tags,
    local.security_tags,
    var.tags
  )}"
}

variable "master_account_assume_role_name" {
  default = "grv_deploy_svc"
}

variable "account_assume_role_name" {
  default = "OrganizationAccountAccessRole"
}
