# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

###Variables for Cognito User Pool

variable "username_attributes" {
  type        = list
  description = "Specifies whether email addresses of phone numbers can be specified as usernames when a user signs up. Conflicts with alias_attributes "
  default     = null
}

variable "alias_attributes" {
  type        = list
  description = "Attributes supported as an alias for this user pool. Possible values: phone_number, email, or preferred_username. Cconflicts with username_attributes."
  default     = null
}

variable "auto_verified_attributes" {
  type        = list
  description = "The attribute to be auto-verified. Possible values: email, phone_number"
  default     = []
}

variable "email_verification_subject" {
  type        = string
  description = "A string representing the email verification subject. Conflicts with verification_message_template configuration block email_subject argument"
  default     = "Your verification code"
}

variable "email_verification_message" {
  type        = string
  description = "A string representing the email verification message. Conflicts with verification_message_template configuration block email_message argument"
  default     = "Your verification code is {####}"
}

variable "mfa_configuration" {
  type        = string
  description = "(Default: OFF) Set to enable multifactor authentication. Must be one of the following values (ON, OFF, OPTIONAL)"
  default     = "OFF"
}

variable "schemas" {
  type        = list(any)
  description = "A container with the schema attributes of a user pool. Maximum of 50 attributes"
  default     = null
}

variable "sms_verification_message" {
  type        = string
  description = "A string representing the SMS verification message. Conficts with verification_message_template configuration block sms_message argument"
  default     = "Your verification code is {####}"
}

variable "sms_authentication_message" {
  type        = string
  description = "A string representing the SMS verification message. Conflicts with verification_message_template configuration block sms_message argument"
  default     = "Your authentication code is {####}"
}

############################################
#######Variable for User Pool Add-ons#######

variable "advanced_security_mode" {
  type        = string
  description = "The mode for advanced security, must be one of OFF, AUDIT or ENFORCED"
  default     = "OFF"
}

# Parameter Store

variable "parameter_store_kms_arn" {
  type        = "string"
  default     = "alias/parameter_store_key"
  description = "The ARN of a KMS key used to encrypt and decrypt SecretString values"
}

data "aws_kms_key" "parameter_store_key" {
  key_id = "alias/parameter_store_key"
}

# Cognito Domain

variable "domain_parent_domain_name" {
  type        = string
  default     = ""
  description = "The custom parent domain string"
}

variable "domain_subdomain_name" {
  type        = string
  default     = "auth"
  description = "The custom sub domain CNAME"
}

variable "domain_certificate_arn" {
  type        = string
  default     = null
  description = "The ARN of an ISSUED ACM certificate in us-east-1 for a custom domain"
}

locals {
  domain_name = var.domain_parent_domain_name != "" ? join(".", concat([var.domain_subdomain_name], compact(split(".", var.domain_parent_domain_name)))) : null
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# User Pool

resource "aws_cognito_user_pool" "pool" {
  count = var.create ? 1 : 0
  name  = local.module_prefix
  tags  = local.tags

  username_attributes      = var.username_attributes
  alias_attributes         = var.alias_attributes
  auto_verified_attributes = var.auto_verified_attributes
  mfa_configuration        = var.mfa_configuration

  admin_create_user_config {
    allow_admin_create_user_only = var.admin_allow_admin_create_user_only
    # unused_account_validity_days = var.unused_account_validity_days
    invite_message_template {
      email_message = var.admin_email_message
      email_subject = var.admin_email_subject
      sms_message   = var.admin_sms_message
    }
  }

  device_configuration {
    challenge_required_on_new_device      = var.device_challenge_required_on_new_device
    device_only_remembered_on_user_prompt = var.device_only_remembered_on_user_prompt
  }

  email_configuration {
    reply_to_email_address = var.email_reply_to_email_address
    source_arn             = var.email_source_arn
    email_sending_account  = var.email_sending_account
  }
  email_verification_subject = var.email_verification_subject
  email_verification_message = var.email_verification_message

  lambda_config {
    pre_sign_up                    = var.pre_sign_up
    pre_authentication             = var.pre_authentication
    custom_message                 = var.custom_message
    post_authentication            = var.post_authentication
    post_confirmation              = var.post_confirmation
    define_auth_challenge          = var.define_auth_challenge
    create_auth_challenge          = var.create_auth_challenge
    verify_auth_challenge_response = var.verify_auth_challenge_response
    user_migration                 = var.user_migration
    pre_token_generation           = var.pre_token_generation
  }

  password_policy {
    require_uppercase = var.require_uppercase
    require_lowercase = var.require_lowercase
    require_numbers   = var.require_numbers
    require_symbols   = var.require_symbols
    minimum_length    = var.minimum_length
    #temporary_password_validity_days = var.temporary_password_validity_days                           
  }

  sms_configuration {
    sns_caller_arn = coalesce(var.sms_sns_caller_arn, aws_iam_role.cognito_sms[0].arn)
    external_id    = coalesce(var.sms_external_id, random_uuid.sms_sns_external_id.result)
  }
  sms_authentication_message = var.sms_authentication_message
  sms_verification_message   = var.sms_verification_message

  user_pool_add_ons {
    advanced_security_mode = var.advanced_security_mode
  }

  verification_message_template {
    default_email_option  = var.verification_default_email_option
    email_message         = var.verification_email_message
    email_message_by_link = var.verification_email_message_by_link
    email_subject         = var.verification_email_subject
    email_subject_by_link = var.verification_email_subject_by_link
    sms_message           = var.verification_sms_message
  }

  dynamic "schema" {
    for_each = var.schemas
    content {
      name                     = schema.value.name
      attribute_data_type      = schema.value.attribute_data_type
      developer_only_attribute = lookup(schema.value, "developer_only_attribute", null)
      mutable                  = lookup(schema.value, "mutable", null)
      required                 = lookup(schema.value, "required", null)

      dynamic "string_attribute_constraints" {
        for_each = schema.value.attribute_data_type == "String" ? [schema] : []
        content {
          min_length = lookup(schema.value, "attribute_constraints_min", null)
          max_length = lookup(schema.value, "attribute_constraints_max", null)
        }
      }

      dynamic "number_attribute_constraints" {
        for_each = schema.value.attribute_data_type == "Number" ? [schema] : []
        content {
          min_value = lookup(schema.value, "attribute_constraints_min", null)
          max_value = lookup(schema.value, "attribute_constraints_max", null)
        }
      }
    }
  }
}

resource "aws_cognito_user_pool_domain" "pool" {
  count = var.create && var.domain_parent_domain_name != "" ? 1 : 0

  domain          = local.domain_name
  certificate_arn = var.domain_certificate_arn
  user_pool_id    = "${aws_cognito_user_pool.pool[0].id}"
}

resource "aws_cognito_user_pool_client" "pool" {
  count = var.create ? 1 : 0
  name  = local.module_prefix

  user_pool_id = "${aws_cognito_user_pool.pool[0].id}"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# User pool

output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.pool[0].id
  description = "The id of the user pool"
}

output "cognito_user_pool_arn" {
  value       = aws_cognito_user_pool.pool[0].arn
  description = "The ARN of the user pool."
}

output "cognito_user_pool_endpoint" {
  value       = aws_cognito_user_pool.pool[0].endpoint
  description = "The endpoint name of the user pool. Example format: cognito-idp.REGION.amazonaws.com/xxxx_yyyyy"
}

output "cognito_user_pool_creation_date" {
  value       = aws_cognito_user_pool.pool[0].creation_date
  description = "The date the user pool was created"
}

output "cognito_user_pool_last_modified_date" {
  value       = aws_cognito_user_pool.pool[0].last_modified_date
  description = "The date the user pool was last modified"
}

output "cognito_admin_create_user_config" {
  value       = aws_cognito_user_pool.pool[0].admin_create_user_config
  description = "The configuration for AdminCreateUser requests"
}

output "cognito_device_configuration" {
  value       = aws_cognito_user_pool.pool[0].device_configuration
  description = "The configuration for the user pool's device tracking"
}

output "cognito_email_configuration" {
  value       = aws_cognito_user_pool.pool[0].email_configuration
  description = "The email configuration associated with the user pool"
}

output "cognito_lambda_config" {
  value       = aws_cognito_user_pool.pool[0].lambda_config
  description = "A container for the AWS Lambda triggers associated with the user pool"
}

output "cognito_password_policy" {
  value       = aws_cognito_user_pool.pool[0].password_policy
  description = "The schemas associated with the user pool"
}

output "cognito_sms_configuration" {
  value       = aws_cognito_user_pool.pool[0].sms_configuration
  description = "The SMS configuration associated with the user pool"
}

output "cognito_user_pool_add_ons" {
  value       = aws_cognito_user_pool.pool[0].user_pool_add_ons
  description = "Configuration block for user pool add-ons to enable user pool advanced security mode features"
}

output "cognito_user_pool_verification_message_template" {
  value       = aws_cognito_user_pool.pool[0].verification_message_template
  description = "The verification message templates configuration"
}

output "cognito_user_pool_schemas" {
  value       = aws_cognito_user_pool.pool[0].schema
  description = "The schemas associated with the user pool"
}

# User Pool Domain

output "cognito_domain_aws_account_id" {
  value       = aws_cognito_user_pool_domain.pool[0].aws_account_id
  description = "The AWS account ID for the user pool owner"
}

output "cognito_domain_cloudfront_distribution_arn" {
  value       = aws_cognito_user_pool_domain.pool[0].cloudfront_distribution_arn
  description = "The ARN of the CloudFront distribution"
}

output "cognito_domain_s3_bucket" {
  value       = aws_cognito_user_pool_domain.pool[0].s3_bucket
  description = "The S3 bucket where the static files for this domain are stored"
}

output "cognito_domain_version" {
  value       = aws_cognito_user_pool_domain.pool[0].version
  description = "The app version"
}

# User Pool Client

output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.pool[0].id
  description = "The S3 bucket where the static files for this domain are stored"
}

output "cognito_client_secret" {
  value       = aws_cognito_user_pool_client.pool[0].client_secret
  description = "The app version"
}
