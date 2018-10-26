terraform {
  required_version = "~> 0.11.8"

  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

provider "aviatrix" {
  controller_ip = "${data.terraform_remote_state.aviatrix_controller.public_ip}"
  username      = "admin"
  password      = "${var.aviatrix_controller_admin_password}"
}

locals {
  account_name = "${join("-", list(var.namespace, var.environment, var.stage))}"
  name_prefix  = "${join("-", list(var.namespace, var.environment, var.stage, var.name))}"

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
