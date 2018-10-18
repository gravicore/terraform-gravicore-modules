locals {
  name_prefix = "${join("-", var.namespace, var.environment, var.stage)}-vpc"

  business_tags = {
    Namespace   = "${var.namespace}"
    Environment = "${var.environment}"
  }

  technical_tags = {
    Stage           = "${var.stage}"
    Repository      = "${var.repository}"
    MasterAccountID = "${var.master_account_id}"
    AccountID       = "${var.account_id}"
    TerraformModule = "github.com/gravicore/terraform-gravicore-modules/aws/vpc"
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
