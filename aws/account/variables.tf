variable "tags" {
  description = "https://aws.amazon.com/answers/account-management/aws-tagging-strategies/"
  default     = {}
}

variable allow_gravicore_access {
  description = "Flag to establish SAML connectivity for Gravicore managed services"
  default     = false
}

variable trusted_entity_account_id {
  description = "Account ID of the trusted entity"
}

variable "iam_account_alias" {
  description = "The account alias to create."
}

variable "aws_region" {
  default = "us-east-1"
}
