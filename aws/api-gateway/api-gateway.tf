variable "cognito_pool_id" {
  type    = string
  default = ""
}

variable "paths" {
  type = map(map(object({
    lambda_arn  = optional(string, "")
    authorizers = optional(list(string), [])
  })))
  default = {}
}

locals {
  permissions = toset(flatten(flatten(
    [for pk, pv in var.paths :
      [for mk, mv in pv : mv.lambda_arn]
    ]
  )))

  paths = {
    for pk, pv in var.paths : pk => {
      for mk, mv in pv : lower(mk) => {
        operationId = "invokeLambda"
        responses = {
          200 = {
            content = { "application/json" = {} }
          }
        }
        security = [for authorizer in try(mv.authorizers, []) : { "${local.module_prefix}-${authorizer}" : [] }]
        x-amazon-apigateway-integration = {
          uri                 = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${mv.lambda_arn}/invocations"
          httpMethod          = "POST"
          type                = "aws_proxy"
          passthroughBehavior = "when_no_match"
        }
      }
    }
  }
}

resource "aws_lambda_permission" "this" {
  for_each      = local.permissions
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*/*"
}

resource "aws_api_gateway_rest_api" "this" {
  name = local.module_prefix
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = local.module_prefix
      version = "1.0"
    }
    paths = local.paths
    components = {
      securitySchemes = {
        "${local.module_prefix}-cognito" = {
          type = "apiKey"
          in   = "header"
          name = "Authorization"

          x-amazon-apigateway-authtype = "cognito_user_pools"
          x-amazon-apigateway-authorizer = {
            type         = "cognito_user_pools"
            providerARNs = ["arn:aws:cognito-idp:${var.aws_region}:${local.account_id}:userpool/${var.cognito_pool_id}"]
          }
        }
      }
    }
  })

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.this.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.environment
}

output "paths" {
  value = local.paths
}

output "permissions" {
  value = local.permissions
}
