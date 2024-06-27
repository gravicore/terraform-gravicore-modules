# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "cognito_user_pool" {
  description = "The Cognito User Pool ID"
  type        = string
  default     = ""
}

variable "appsync_api_ids" {
  description = "The AppSync API IDs to associate with the Merged AppSync API"
  type        = list(string)
  default     = []
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

locals {
  variables = {
    APPSYNC_API_IDS      = jsonencode(var.appsync_api_ids)
    APPSYNC_API_NAME     = local.module_prefix
    AWS_REGION           = var.aws_region
    COGNITO_USER_POOL_ID = var.cognito_user_pool
    EXECUTION_ROLE_ARN   = var.create ? aws_iam_role.this[0].arn : ""
  }
  environment = join(" ", [for k, v in local.variables : "${k}='${v}'"])
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
}

resource "null_resource" "create" {
  count = var.create ? 1 : 0
  triggers = {
    always_create = "${timestamp()}"
  }

  provisioner "local-exec" {
    when    = create
    command = "pip install -qq boto3 && ${local.environment} python bin/create.py"
  }
}

resource "null_resource" "destroy" {
  count = var.create ? 1 : 0
  triggers = {
    api_name = local.module_prefix
  }

  provisioner "local-exec" {
    when    = destroy
    command = "pip install -qq boto3 && APPSYNC_API_NAME=${self.triggers.api_name} python bin/destroy.py"
  }
}

data "external" "this" {
  count      = var.create ? 1 : 0
  program    = ["sh", "-c", "cat output.json"]
  depends_on = [null_resource.create[0]]
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "appsync_api_id" {
  value = concat(data.external.this.*.result.api_id, [""])[0]
}
