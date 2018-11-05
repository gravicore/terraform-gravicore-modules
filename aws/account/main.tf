terraform {
  required_version = "~> 0.11.8"
}

module "gravicore_access" {
  source = "./modules/gravicore-access"

  allow_gravicore_access    = "${var.allow_gravicore_access}"
  trusted_entity_account_id = "${var.account_id}"
}

module "iam" {
  source = "./modules/iam"
  tags   = "${var.tags}"

  allow_gravicore_access    = "${var.allow_gravicore_access}"
  trusted_entity_account_id = "${var.account_id}"
}

locals {
  is_master = "${var.master_account_id == var.account_id ? 1 : 0 }"
  is_child  = "${var.master_account_id != var.account_id ? 1 : 0 }"
}
