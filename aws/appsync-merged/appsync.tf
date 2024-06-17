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
    EXECUTION_ROLE_ARN   = aws_iam_role.this.arn
  }
  environment = join(" ", [for k, v in local.variables : "${k}='${v}'"])
}

resource "aws_iam_role" "this" {
  name = local.module_prefix

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
  name   = local.module_prefix
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
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

data "aws_caller_identity" "this" {}

resource "null_resource" "create" {
  triggers = {
    always_create = "${timestamp()}"
  }

  provisioner "local-exec" {
    when    = create
    command = "pip install -qq boto3 && ${local.environment} python bin/create.py"
  }
}

resource "null_resource" "destroy" {
  triggers = {
    api_name = local.module_prefix
  }

  provisioner "local-exec" {
    when    = destroy
    command = "pip install -qq boto3 && APPSYNC_API_NAME=${self.triggers.api_name} python bin/destroy.py"
  }
}

data "external" "this" {
  program    = ["sh", "-c", "cat output.json"]
  depends_on = [null_resource.create]
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "appsync_api_id" {
  value = data.external.this.result.api_id
}
