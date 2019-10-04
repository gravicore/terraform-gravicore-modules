resource "aws_iam_account_alias" "alias" {
  account_alias = coalesce(var.iam_account_alias, local.stage_prefix)
}

# --------------------------------------------------------------------------------------------------
# Password Policy
# --------------------------------------------------------------------------------------------------

resource "aws_iam_account_password_policy" "default" {
  minimum_password_length        = var.minimum_password_length
  password_reuse_prevention      = var.password_reuse_prevention
  require_lowercase_characters   = var.require_lowercase_characters
  require_numbers                = var.require_numbers
  require_uppercase_characters   = var.require_uppercase_characters
  require_symbols                = var.require_symbols
  allow_users_to_change_password = var.allow_users_to_change_password
  max_password_age               = var.max_password_age
}
