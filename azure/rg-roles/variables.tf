data "azurerm_subscription" "current" {}

# devop variables

variable "devop_policy_allow" {
  type    = list(string)
  default = ["*"]
}

variable "devop_policy_deny" {
  type    = list(string)
  default = []
}

# developer variables

variable "developer_policy_allow" {
  type    = list(string)
  default = ["*"]
}

variable "developer_policy_deny" {
  type = list(string)
  default = [
    "iam:Add*",
    "iam:Attach*",
    "iam:Change*",
    "iam:Create*",
    "iam:Deactivate*",
    "iam:Delete*",
    "iam:Detach*",
    "iam:Enable*",
    "iam:Put*",
    "iam:Remove*",
    "iam:Reset*",
    "iam:Resync*",
    "iam:Set*",
    "iam:Tag*",
    "iam:Untag*",
    "iam:Update*",
    "iam:Upload*",
  ]
}
