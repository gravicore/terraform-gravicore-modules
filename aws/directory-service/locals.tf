# data "aws_caller_identity" "this" {}
module "common_label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=master"
  namespace   = "${var.namespace}"
  environment = "${var.environment}"
  stage       = "${var.stage}"
}

locals {
  technical_tags = {
    AccountID  = "${var.account_id}"
    Repository = "${var.repository}"
  }

  business_tags = {}

  automation_tags = {}

  security_tags = {}

  default_tags = "${merge(
    map("Namespace", module.common_label.tags["Namespace"]),
    map("Environment", module.common_label.tags["Environment"]),
    map("Stage", module.common_label.tags["Stage"]),
    local.technical_tags,
    local.business_tags,
    local.automation_tags,
    local.security_tags
  )}"
}
