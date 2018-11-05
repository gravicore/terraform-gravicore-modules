terraform {
  required_version = "~> 0.11.8"

  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

# specify aviatrix as the provider with these parameters:
# controller_ip - public IP address of the controller
# username - login user name, default is admin
# password - password

provider "aviatrix" {
  controller_ip = "${data.terraform_remote_state.aviatrix_controller.public_ip}"
  username      = "admin"
  password      = "${data.terraform_remote_state.aviatrix_controller.private_ip}"
}

locals {
  name_prefix = "${join("-", list(var.namespace, var.environment, var.stage, var.name))}"

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
