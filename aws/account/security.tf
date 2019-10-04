# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

locals {
  is_master = "${var.master_account_id == var.account_id ? 1 : 0}"
  is_child  = "${var.master_account_id != var.account_id ? 1 : 0}"

  account_name = local.stage_prefix
}
