terraform {
  required_version = ">= 0.12"

  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

provider "aws" {
  version = "~> 2.26.0"
  region  = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/grv_deploy_svc"
  }
}

locals {
  name_prefix = join("-", [var.namespace, var.environment, var.stage, var.name])

  business_tags = {
    Namespace   = var.namespace
    Environment = var.environment
  }

  technical_tags = {
    Stage           = var.stage
    Repository      = var.repository
    MasterAccountID = var.master_account_id
    AccountID       = var.account_id
    TerraformModule = var.terraform_module
  }

  automation_tags = {}

  security_tags = {}

  tags = merge(
    local.technical_tags,
    local.business_tags,
    local.automation_tags,
    local.security_tags,
    var.tags,
  )
}

