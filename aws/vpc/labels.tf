module "common_label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.5.3"
  namespace   = "${var.namespace}"
  environment = "${var.environment}"
  stage       = "${var.stage}"
}

module "module_label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.5.3"
  context = "${module.common_label.context}"
  name    = "vpc"
}

locals {
  technical_tags = {
    MasterAccountID = "${var.master_account_id}"
    AccountID       = "${var.account_id}"
    Repository      = "${var.repository}"
  }

  business_tags = {}

  automation_tags = {
    TerraformModule = "github.com/gravicore/terraform-gravicore-modules/aws/vpc"
  }

  security_tags = {}

  tags = "${merge(
    map("Namespace", module.module_label.tags["Namespace"]),
    map("Environment", module.module_label.tags["Environment"]),
    map("Stage", module.common_module.tags["Stage"]),
    local.technical_tags,
    local.business_tags,
    local.automation_tags,
    local.security_tags,
    var.tags
  )}"
}
