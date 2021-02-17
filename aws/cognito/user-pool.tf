# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

###Variables for Cognito User Pool

variable username_attributes {
  type        = list
  description = "Specifies whether email addresses of phone numbers can be specified as usernames when a user signs up. Conflicts with alias_attributes "
  default     = null
}

variable alias_attributes {
  type        = list
  description = "Attributes supported as an alias for this user pool. Possible values: phone_number, email, or preferred_username. Cconflicts with username_attributes."
  default     = null
}

variable auto_verified_attributes {
  type        = list
  description = "The attribute to be auto-verified. Possible values: email, phone_number"
  default     = []
}

variable email_verification_subject {
  type        = string
  description = "A string representing the email verification subject. Conflicts with verification_message_template configuration block email_subject argument"
  default     = "Your verification code"
}

variable email_verification_message {
  type        = string
  description = "A string representing the email verification message. Conflicts with verification_message_template configuration block email_message argument"
  default     = "Your verification code is {####}"
}

variable mfa_configuration {
  type        = string
  description = "(Default: OFF) Set to enable multifactor authentication. Must be one of the following values (ON, OFF, OPTIONAL)"
  default     = "OFF"
}

variable schemas {
  type        = list(any)
  description = "A container with the schema attributes of a user pool. Maximum of 50 attributes"
  default     = null
}

variable sms_verification_message {
  type        = string
  description = "A string representing the SMS verification message. Conficts with verification_message_template configuration block sms_message argument"
  default     = "Your verification code is {####}"
}

variable sms_authentication_message {
  type        = string
  description = "A string representing the SMS verification message. Conflicts with verification_message_template configuration block sms_message argument"
  default     = "Your authentication code is {####}"
}

locals {
  sms_configuration = var.mfa_configuration != "OFF" ? { sms_configuration = {
    sns_caller_arn = coalesce(var.sms_sns_caller_arn, aws_iam_role.cognito_sms[0].arn),
    external_id    = coalesce(var.sms_external_id, random_uuid.sms_sns_external_id[0].result)
  } } : {}
}

############################################
#######Variable for User Pool Add-ons#######

variable advanced_security_mode {
  type        = string
  description = "The mode for advanced security, must be one of OFF, AUDIT or ENFORCED"
  default     = "OFF"
}

# Parameter Store

variable parameter_store_kms_arn {
  type        = string
  default     = "alias/parameter_store_key"
  description = "The ARN of a KMS key used to encrypt and decrypt SecretString values"
}

data "aws_kms_key" "parameter_store_key" {
  key_id = "alias/parameter_store_key"
}

# Cognito Domain

variable create_domain_name {
  type        = bool
  default     = true
  description = "Create cognito domain name"
}

variable domain_parent_domain_name {
  type        = string
  default     = ""
  description = "The custom parent domain string"
}

variable domain_subdomain_name {
  type        = string
  default     = ""
  description = "The custom sub domain CNAME"
}

variable domain_certificate_arn {
  type        = string
  default     = null
  description = "The ARN of an ISSUED ACM certificate in us-east-1 for a custom domain"
}

locals {
  domain_name = var.domain_parent_domain_name != "" ? join(".", concat([var.domain_subdomain_name], compact(split(".", var.domain_parent_domain_name)))) : null
}

# Cognito Identity Provider

variable cognito_identity_provider {
  type        = map
  default     = {}
  description = "Map for building Cognito Identity Providers"
}

# Cognito User Pool Client

variable allowed_oauth_flows {
  type        = list(string)
  default     = null
  description = "(Optional) List of allowed OAuth flows (code, implicit, client_credentials)"
}

variable allowed_oauth_flows_user_pool_client {
  type        = bool
  default     = null
  description = "(Optional) Whether the client is allowed to follow the OAuth protocol when interacting with Cognito user pools"
}

variable allowed_oauth_scopes {
  type        = list(string)
  default     = null
  description = "(Optional) List of allowed OAuth scopes (phone, email, openid, profile, and aws.cognito.signin.user.admin)"
}

variable callback_urls {
  type        = list(string)
  default     = null
  description = "(Optional) List of allowed callback URLs for the identity providers"
}

variable default_redirect_uri {
  type        = string
  default     = null
  description = "(Optional) The default redirect URI. Must be in the list of callback URLs"
}

variable explicit_auth_flows {
  type        = list(string)
  default     = null
  description = "(Optional) List of authentication flows (ADMIN_NO_SRP_AUTH, CUSTOM_AUTH_FLOW_ONLY, USER_PASSWORD_AUTH, ALLOW_ADMIN_USER_PASSWORD_AUTH, ALLOW_CUSTOM_AUTH, ALLOW_USER_PASSWORD_AUTH, ALLOW_USER_SRP_AUTH, ALLOW_REFRESH_TOKEN_AUTH)"
}

variable generate_secret {
  type        = bool
  default     = null
  description = "(Optional) Should an application secret be generated"
}

variable logout_urls {
  type        = list(string)
  default     = null
  description = "(Optional) List of allowed logout URLs for the identity providers"
}

variable prevent_user_existence_errors {
  type        = string
  default     = null
  description = "(Optional) Choose which errors and responses are returned by Cognito APIs during authentication, account confirmation, and password recovery when the user does not exist in the user pool. When set to ENABLED and the user does not exist, authentication returns an error indicating either the username or password was incorrect, and account confirmation and password recovery return a response indicating a code was sent to a simulated destination. When set to LEGACY, those APIs will return a UserNotFoundException exception if the user does not exist in the user pool"
}

variable read_attributes {
  type        = list(string)
  default     = null
  description = "(Optional) List of user pool attributes the application client can read from"
}

variable supported_identity_providers {
  type        = list(string)
  default     = []
  description = "(Optional) List of provider names for the identity providers that are supported on this client"
}

variable write_attributes {
  type        = list(string)
  default     = null
  description = "(Optional) List of user pool attributes the application client can write to"
}

variable refresh_token_validity {
  type        = number
  default     = 1
  description = "(Optional) The time limit in days refresh tokens are valid for"
}

variable additional_app_clients {
  type        = map(any)
  default     = {}
  description = ""
}

variable resource_servers {
  type        = list(any)
  default     = []
  description = "description"
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
    from_email_address     = var.email_from_email_address
    reply_to_email_address = var.email_reply_to_email_address
    source_arn             = var.email_source_arn
    email_sending_account  = var.email_sending_account
  }
  email_verification_subject = var.email_verification_subject
  email_verification_message = var.email_verification_message

  dynamic "lambda_config" {
    for_each = local.lambda_config
    content {
      pre_sign_up                    = lookup(lambda_config.value, "pre_sign_up", null)
      pre_authentication             = lookup(lambda_config.value, "pre_authentication", null)
      custom_message                 = lookup(lambda_config.value, "custom_message", null)
      post_authentication            = lookup(lambda_config.value, "post_authentication", null)
      post_confirmation              = lookup(lambda_config.value, "post_confirmation", null)
      define_auth_challenge          = lookup(lambda_config.value, "define_auth_challenge", null)
      create_auth_challenge          = lookup(lambda_config.value, "create_auth_challenge", null)
      verify_auth_challenge_response = lookup(lambda_config.value, "verify_auth_challenge_response", null)
      user_migration                 = lookup(lambda_config.value, "user_migration", null)
      pre_token_generation           = lookup(lambda_config.value, "pre_token_generation", null)
    }
  }

  password_policy {
    require_uppercase                = var.require_uppercase
    require_lowercase                = var.require_lowercase
    require_numbers                  = var.require_numbers
    require_symbols                  = var.require_symbols
    minimum_length                   = var.minimum_length
    temporary_password_validity_days = var.temporary_password_validity_days
  }

  dynamic "sms_configuration" {
    for_each = local.sms_configuration
    content {
      sns_caller_arn = lookup(sms_configuration.value, "sns_caller_arn", null)
      external_id    = lookup(sms_configuration.value, "external_id", null)
    }
  }
  sms_authentication_message = var.mfa_configuration != "OFF" ? var.sms_authentication_message : null
  sms_verification_message   = var.mfa_configuration != "OFF" ? var.sms_verification_message : null

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
  # lifecycle 
}

resource "aws_cognito_user_pool_domain" "pool" {
  count = var.create && var.create_domain_name ? 1 : 0

  domain          = local.domain_name != null ? local.domain_name : var.domain_subdomain_name != "" ? join("-", [local.stage_prefix, var.domain_subdomain_name]) : local.stage_prefix
  certificate_arn = local.domain_name != null ? var.domain_certificate_arn : null
  user_pool_id    = aws_cognito_user_pool.pool[0].id
}

resource "aws_cognito_resource_server" "pool" {
  count      = var.create && length(var.resource_servers) >= 1 ? 1 : 0
  identifier = "https://${concat(aws_cognito_user_pool_domain.pool.*.domain, [""])[0]}.auth.${var.aws_region}.amazoncognito.com"
  name       = local.module_prefix

  dynamic "scope" {
    for_each = var.resource_servers
    content {
      scope_name        = scope.value.scope_name
      scope_description = lookup(scope.value, "scope_description", null)
    }
  }

  user_pool_id = aws_cognito_user_pool.pool[0].id
}

resource "aws_cognito_user_pool_client" "pool" {
  count = var.create ? 1 : 0
  name  = local.module_prefix

  allowed_oauth_flows                  = var.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = var.allowed_oauth_flows_user_pool_client
  allowed_oauth_scopes                 = var.allowed_oauth_scopes
  callback_urls                        = var.callback_urls
  default_redirect_uri                 = var.default_redirect_uri
  explicit_auth_flows                  = var.explicit_auth_flows
  generate_secret                      = var.generate_secret
  logout_urls                          = var.logout_urls
  prevent_user_existence_errors        = var.prevent_user_existence_errors
  supported_identity_providers         = concat([for p in aws_cognito_identity_provider.pool : p.provider_name], var.supported_identity_providers)
  user_pool_id                         = aws_cognito_user_pool.pool[0].id
  read_attributes                      = var.read_attributes
  write_attributes                     = var.write_attributes
  refresh_token_validity               = var.refresh_token_validity
  depends_on = [
    aws_cognito_identity_provider.pool,
  ]
}

resource "aws_cognito_user_pool_client" "additional_client" {
  for_each = var.create ? var.additional_app_clients : {}
  name     = join(var.delimiter, [local.module_prefix, each.key])

  allowed_oauth_flows                  = lookup(each.value, "allowed_oauth_flows", null)
  allowed_oauth_flows_user_pool_client = lookup(each.value, "allowed_oauth_flows_user_pool_client", null)
  allowed_oauth_scopes                 = formatlist("${aws_cognito_resource_server.pool[0].identifier}/%s", lookup(each.value, "allowed_oauth_scopes", null))
  callback_urls                        = lookup(each.value, "callback_urls", null)
  logout_urls                          = lookup(each.value, "logout_urls", null)
  default_redirect_uri                 = lookup(each.value, "default_redirect_uri", null)
  explicit_auth_flows                  = lookup(each.value, "explicit_auth_flows", null)
  generate_secret                      = lookup(each.value, "generate_secret", null)
  prevent_user_existence_errors        = lookup(each.value, "prevent_user_existence_errors", null)
  supported_identity_providers         = lookup(each.value, "supported_identity_providers", null)
  user_pool_id                         = aws_cognito_user_pool.pool[0].id
  read_attributes                      = lookup(each.value, "read_attributes", null)
  write_attributes                     = lookup(each.value, "write_attributes", null)
  refresh_token_validity               = lookup(each.value, "refresh_token_validity", 1)
  depends_on = [
    aws_cognito_identity_provider.pool,
  ]
}

resource "aws_cognito_identity_provider" "pool" {
  for_each = var.cognito_identity_provider

  user_pool_id = aws_cognito_user_pool.pool[0].id

  provider_name = each.key
  provider_type = each.value.type

  provider_details  = lookup(each.value, "provider_details", null)
  attribute_mapping = lookup(each.value, "attribute_mapping", null)
  idp_identifiers   = lookup(each.value, "idp_identifiers", null)
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

output "cognito_domain_name" {
  value       = aws_cognito_user_pool_domain.pool.*.domain != null ? "${concat(aws_cognito_user_pool_domain.pool.*.domain, [""])[0]}.auth.${var.aws_region}.amazoncognito.com" : null
  description = "The domain string for the user pool"
}

output "cognito_domain_aws_account_id" {
  value       = concat(aws_cognito_user_pool_domain.pool.*.aws_account_id, [""])[0]
  description = "The AWS account ID for the user pool owner"
}

output "cognito_domain_cloudfront_distribution_arn" {
  value       = concat(aws_cognito_user_pool_domain.pool.*.cloudfront_distribution_arn, [""])[0]
  description = "The ARN of the CloudFront distribution"
}

output "cognito_domain_s3_bucket" {
  value       = concat(aws_cognito_user_pool_domain.pool.*.s3_bucket, [""])[0]
  description = "The S3 bucket where the static files for this domain are stored"
}

output "cognito_domain_version" {
  value       = concat(aws_cognito_user_pool_domain.pool.*.version, [""])[0]
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

output "cognito_client_callback_urls" {
  value       = aws_cognito_user_pool_client.pool[0].callback_urls
  description = ""
}

output "cognito_client_logout_urls" {
  value       = aws_cognito_user_pool_client.pool[0].logout_urls
  description = ""
}

output additional_app_client_id {
  value       = values(aws_cognito_user_pool_client.additional_client)[*].id
  sensitive   = false
  description = ""
  depends_on = [
    aws_cognito_user_pool_client.additional_client,
  ]
}

output resource_server {
  value       = aws_cognito_resource_server.pool
  sensitive   = false
  description = ""
  depends_on = [
    aws_cognito_user_pool_client.pool
  ]
}
