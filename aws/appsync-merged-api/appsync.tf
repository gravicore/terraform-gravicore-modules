# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "cognito_user_pool_id" {
  description = "The Cognito User Pool ID"
  type        = string
  default     = ""
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
resource "null_resource" "destroy" {
  triggers = local.triggers

  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
      pip install --force-reinstall -qq boto3 && \
      APPSYNC_API_NAME=${self.triggers.APPSYNC_API_NAME} \
      python ${path.module}/bin/destroy.py
EOF
  }
}

data "external" "this" {
  count      = var.create ? 1 : 0
  program    = ["sh", "-c", "cat ${path.module}/output.json"]
  depends_on = [null_resource.create[0]]
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "appsync_merged_api_id" {
  value = concat(data.external.this.*.result.api_id, [""])[0]
}
