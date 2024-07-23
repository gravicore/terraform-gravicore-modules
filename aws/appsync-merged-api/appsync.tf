# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "cognito_user_pool_id" {
  description = "The Cognito User Pool ID"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "The domain name to associate with the AppAsync API."
  type        = string
}

variable "subdomain_name" {
  description = "The subdomain name to associate with the AppAsync API."
  type        = string
}

variable "certificate_arn" {
  type        = string
  description = "The certificate to associate with the Custom Domain."
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

locals {
  triggers = {
    APPSYNC_API_NAME     = local.module_prefix
    AWS_REGION           = var.aws_region
    COGNITO_USER_POOL_ID = var.cognito_user_pool_id
    EXECUTION_ROLE_ARN   = var.create ? aws_iam_role.this[0].arn : ""
    MODULE_PATH          = path.module
  }
  environment = join(" ", [for k, v in local.triggers : "${k}='${v}'"])
}

resource "aws_iam_role" "this" {
  count = var.create ? 1 : 0
  name  = local.module_prefix

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "appsync.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "this" {
  count  = var.create ? 1 : 0
  name   = local.module_prefix
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.this[0].json
}

data "aws_iam_policy_document" "this" {
  count = var.create ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${local.account_id}:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["appsync:SourceGraphQL"]
    resources = ["arn:aws:appsync:${var.aws_region}:${local.account_id}:apis/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["appsync:StartSchemaMerge"]
    resources = ["arn:aws:appsync:${var.aws_region}:${local.account_id}:apis/*/sourceApiAssociations/*"]
  }
}

resource "null_resource" "create" {
  count    = var.create ? 1 : 0
  triggers = merge({ always_run = timestamp() }, local.triggers)

  provisioner "local-exec" {
    when    = create
    command = <<EOF
      pip install --force-reinstall -qq boto3 && \
      ${local.environment} \
      python ${path.module}/bin/create.py
EOF
  }

  depends_on = [null_resource.destroy]
}

# - adding counts may prevent destruction
# - changing names may prevent destruction
# - commands can't access local variables during destruction
# summary: without a provider, handling destruction is tricky
# disabling destroy by default, as it is too dangerous without a provider
resource "null_resource" "destroy" {
  triggers = local.triggers

  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
      pip install --force-reinstall -qq boto3 && \
      APPSYNC_API_NAME=${self.triggers.APPSYNC_API_NAME} \
      DISABLED="true" \
      python ${path.module}/bin/destroy.py
EOF
  }
}

data "local_file" "this" {
  depends_on = [null_resource.create]
  filename   = "${path.module}/output.json"
}

resource "aws_appsync_domain_name" "default" {
  count      = var.create ? 1 : 0
  depends_on = [null_resource.create]

  domain_name     = "${var.subdomain_name}.${var.domain_name}"
  description     = "create custom domain name for appsync"
  certificate_arn = var.certificate_arn
}

resource "aws_appsync_domain_name_api_association" "this" {
  count      = var.create ? 1 : 0
  depends_on = [null_resource.create]

  api_id      = jsondecode(data.local_file.this.content).api_id
  domain_name = aws_appsync_domain_name.default[0].domain_name
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "appsync_merged_api_id" {
  value = var.create ? jsondecode(data.local_file.this.content).api_id : ""
}

output "appsync_merged_api_domain_name" {
  value = concat(aws_appsync_domain_name.default.*.appsync_domain_name, [""])[0]
}

output "appsync_merged_api_zone_id" {
  value = concat(aws_appsync_domain_name.default.*.hosted_zone_id, [""])[0]
}
