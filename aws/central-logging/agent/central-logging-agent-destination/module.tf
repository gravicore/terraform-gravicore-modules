variable "master_account_assume_role_name" {
  default = "grv_deploy_svc"
}

locals {
  is_master = var.master_account_id == var.account_id ? 1 : 0
  is_child  = var.master_account_id != var.account_id ? 1 : 0

  environment_prefix = join("-", [var.namespace, var.environment])
  stage_prefix       = join("-", [var.namespace, var.environment, var.stage])

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

