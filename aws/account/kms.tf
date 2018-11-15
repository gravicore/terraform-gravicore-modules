module "rds_kms_key" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=0.1.2"
  namespace               = ""
  stage                   = ""
  name                    = "${local.account_name}-rds"
  description             = "KMS key for rds"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/${replace(local.account_name, "-", "/")}/rds"
  tags                    = "${local.tags}"
}

output "rds_key_arn" {
  value       = "${module.rds_kms_key.key_arn}"
  description = "Key ARN"
}
