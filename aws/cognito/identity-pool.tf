# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "identity_pool_allow_unauthenticated_identities" {
  type        = bool
  default     = false
  description = "Whether the identity pool supports unauthenticated logins or not"
}

variable "identity_pool_developer_provider_name" {
  type        = string
  default     = null
  description = "The 'domain' by which Cognito will refer to your users. This name acts as a placeholder that allows your backend and the Cognito service to communicate about the developer provider"
}

variable "identity_pool_cognito_identity_providers" {
  type = list(object({
    client_id               = string
    provider_name           = string
    server_side_token_check = bool
  }))
  default     = null
  description = "An array of Amazon Cognito Identity user pools and their client IDs"
}

variable "identity_pool_openid_connect_provider_arns" {
  type        = list(string)
  default     = null
  description = "A list of OpendID Connect provider ARNs"
}

variable "identity_pool_saml_provider_arns" {
  type        = list(string)
  default     = null
  description = "An array of Amazon Resource Names (ARNs) of the SAML provider for your identity"
}

variable "identity_pool_supported_login_providers" {
  type        = map(string)
  default     = null
  description = "Key-Value pairs mapping provider names to provider app IDs"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Identity Pool

resource "aws_cognito_identity_pool" "pool" {
  count              = var.create ? 1 : 0
  identity_pool_name = replace(local.module_prefix, var.delimiter, " ")
  tags               = local.tags

  allow_unauthenticated_identities = var.identity_pool_allow_unauthenticated_identities

  developer_provider_name = var.identity_pool_developer_provider_name
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.pool[0].id
    provider_name           = aws_cognito_user_pool.pool[0].endpoint
    server_side_token_check = false
  }
  dynamic "cognito_identity_providers" {
    for_each = var.identity_pool_cognito_identity_providers != null ? var.identity_pool_cognito_identity_providers : []
    content {
      client_id               = aws_cognito_user_pool_client.pool[0].id
      provider_name           = aws_cognito_user_pool.pool[0].endpoint
      server_side_token_check = false
    }
  }
  openid_connect_provider_arns = var.identity_pool_openid_connect_provider_arns
  saml_provider_arns           = var.identity_pool_saml_provider_arns
  supported_login_providers    = var.identity_pool_supported_login_providers
}

# Unauthorized IAM

resource "aws_iam_role" "cognito_unauthorized" {
  count = var.create ? 1 : 0
  name  = "${local.module_prefix}-unauth"
  tags  = local.tags
  # path = "/service-role/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.pool[0].id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "unauthenticated"
        }
      }
    }
  ]
}
POLICY
}

data "aws_iam_policy_document" "cognito_unauthorized" {
  count = var.create ? 1 : 0

  statement {
    actions = [
      "mobileanalytics:PutEvents",
      "cognito-sync:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cognito_unauthorized" {
  count = var.create ? 1 : 0
  name  = "${local.module_prefix}-unauth-access"

  role   = aws_iam_role.cognito_unauthorized[0].name
  policy = data.aws_iam_policy_document.cognito_unauthorized[0].json
}

# Authoried IAM

resource "aws_iam_role" "cognito_authorized" {
  count = var.create ? 1 : 0
  name  = "${local.module_prefix}-auth"
  tags  = local.tags
  # path = "/service-role/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.pool[0].id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "authenticated"
        }
      }
    }
  ]
}
POLICY
}

data "aws_iam_policy_document" "cognito_authorized" {
  count = var.create ? 1 : 0

  statement {
    actions = [
      "mobileanalytics:PutEvents",
      "cognito-sync:*",
      "cognito-identity:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cognito_authorized" {
  count = var.create ? 1 : 0
  name  = "${local.module_prefix}-auth-access"

  role   = aws_iam_role.cognito_authorized[0].name
  policy = data.aws_iam_policy_document.cognito_authorized[0].json
}

# Roles attachment

resource "aws_cognito_identity_pool_roles_attachment" "pool" {
  count = var.create ? 1 : 0

  identity_pool_id = "${aws_cognito_identity_pool.pool[0].id}"
  roles = {
    "authenticated"   = "${aws_iam_role.cognito_authorized[0].arn}"
    "unauthenticated" = "${aws_iam_role.cognito_unauthorized[0].arn}"
  }
  #   role_mapping {
  #     identity_provider         = "graph.facebook.com"
  #     ambiguous_role_resolution = "AuthenticatedRole"
  #     type                      = "Rules"

  #     mapping_rule {
  #       claim      = "isAdmin"
  #       match_type = "Equals"
  #       role_arn   = aws_iam_role.cognito_authorized[0].arn
  #       value      = "paid"
  #     }
  #   }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# Identity Pool

output "cognito_identity_pool_id" {
  value       = aws_cognito_identity_pool.pool[0].id
  description = "An identity pool ID in the format REGION:GUID"
}

output "cognito_identity_pool_arn" {
  value       = aws_cognito_identity_pool.pool[0].arn
  description = "The ARN of the identity pool"
}

output "cognito_identity_pool_allow_unauthenticated_identities" {
  value       = aws_cognito_identity_pool.pool[0].allow_unauthenticated_identities
  description = "Whether the identity pool supports unauthenticated logins or not"
}

output "cognito_identity_pool_developer_provider_name" {
  value       = aws_cognito_identity_pool.pool[0].developer_provider_name
  description = "The 'domain' by which Cognito will refer to your users. This name acts as a placeholder that allows your backend and the Cognito service to communicate about the developer provider"
}

output "cognito_identity_pool_cognito_identity_providers" {
  value       = aws_cognito_identity_pool.pool[0].cognito_identity_providers
  description = "An array of Amazon Cognito Identity user pools and their client IDs"
}

output "cognito_identity_pool_openid_connect_provider_arns" {
  value       = aws_cognito_identity_pool.pool[0].openid_connect_provider_arns
  description = "A list of OpendID Connect provider ARNs"
}

output "cognito_identity_pool_saml_provider_arns" {
  value       = aws_cognito_identity_pool.pool[0].saml_provider_arns
  description = "An array of Amazon Resource Names (ARNs) of the SAML provider for your identity"
}

output "cognito_identity_pool_supported_login_providers" {
  value       = aws_cognito_identity_pool.pool[0].supported_login_providers
  description = "Key-Value pairs mapping provider names to provider app IDs"
}
