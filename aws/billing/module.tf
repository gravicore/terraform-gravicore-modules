terraform {
  required_version = ">= 0.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.26"
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Shared Variables
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  default = "billing"
}

variable "create" {
  default = true
}

variable "aws_region" {
  default = "us-east-1"
}

variable "terraform_module" {
  default = "gravicore/terraform-gravicore-modules/aws/billing"
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

variable "master_account_id" {
}

variable "account_id" {
}

variable "master_account_assume_role_name" {
  default = "grv-service-deployment"
}

variable "account_assume_role_name" {
  default = "OrganizationAccountAccessRole"
}

variable "desc_prefix" {
  default = "Gravicore:"
}

variable "tags" {
  default = {}
}

locals {
  environment_prefix = join("-", [var.namespace, var.environment])
  stage_prefix       = join("-", [var.namespace, var.environment, var.stage])
  module_prefix      = join("-", [var.namespace, var.environment, var.stage, var.name])

  business_tags = {
    namespace   = var.namespace
    environment = var.environment
  }

  technical_tags = {
    stage             = var.stage
    repository        = var.repository
    master_account_id = var.master_account_id
    account_id        = var.account_id
    terraform_module  = var.terraform_module
  }

  automation_tags = {}

  security_tags = {}

  tags = merge(
    local.business_tags,
    local.technical_tags,
    local.automation_tags,
    local.security_tags,
    var.tags,
  )
}

