variable "name_prefix" {
  default = "grv"
}

variable "tags" {
  description = "https://aws.amazon.com/answers/account-management/aws-tagging-strategies/"

  default = {
    TerraformModule = "gravicore/terraform-aws-organization"
  }
}

variable "allow_gravicore_access" {
  description = "Flag to establish SAML connectivity for Gravicore managed services"
  default     = false
}

variable "trusted_entity_account_id" {
  description = "Account ID of the trusted entity"
}

variable "aws_region" {
  description = "The region where resources will be deployed"
  default     = "us-east-1"
}

variable "max_password_age" {
  description = "The number of days that an user password is valid."
  default     = 90
}

variable "minimum_password_length" {
  description = "Minimum length to require for user passwords."
  default     = 14
}

variable "password_reuse_prevention" {
  description = "The number of previous passwords that users are prevented from reusing."
  default     = 24
}

variable "require_lowercase_characters" {
  description = "Whether to require lowercase characters for user passwords."
  default     = true
}

variable "require_numbers" {
  description = "Whether to require numbers for user passwords."
  default     = true
}

variable "require_uppercase_characters" {
  description = "Whether to require uppercase characters for user passwords."
  default     = true
}

variable "require_symbols" {
  description = "Whether to require symbols for user passwords."
  default     = true
}

variable "allow_users_to_change_password" {
  description = "Whether to allow users to change their own password."
  default     = true
}

