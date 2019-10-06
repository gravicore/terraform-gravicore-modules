variable "aviatrix_accounts" {
  type        = map
  default     = {}
  description = "A list of AWS Account IDs to add to the Aviatrix Controller"
}

resource "aviatrix_account" "accounts" {
  for_each = var.aviatrix_accounts

  account_name = each.key
  cloud_type   = 1

  aws_iam            = true
  aws_account_number = each.value
  aws_role_app       = "arn:aws:iam::${each.value}:role/aviatrix-role-app"
  aws_role_ec2       = "arn:aws:iam::${each.value}:role/aviatrix-role-ec2"

  # aws_access_key  = ""
  # aws_secret_key = ""
}
