variable "cognito_pool_id" {
  type    = string
  default = ""
}

variable "domain" {
  type = object({
    zone = object({
      id   = string
      name = string
    })
    certificate_arn = string
  })
}

variable "paths" {
  type = map(map(object({
    lambda_arn  = optional(string, "")
    authorizers = optional(list(string), [])
  })))
  default = {}
}

variable "private" {
  type = object({
    vpc     = string
    subnets = list(string)
  })
  default = null
}

locals {
  custom_domain = "${var.name}.${var.domain.zone.name}"
  endpoint_types = [var.private != null ? "PRIVATE" : "REGIONAL"]

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
    types            = local.endpoint_types
    vpc_endpoint_ids = var.private != null ? [aws_vpc_endpoint.this[0].id] : []
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

resource "aws_security_group" "this" {
  count  = var.private != null ? 1 : 0
  vpc_id = var.private.vpc

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "this" {
  count               = var.private != null ? 1 : 0
  vpc_id              = var.private.vpc
  service_name        = "com.amazonaws.${var.aws_region}.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private.subnets
  security_group_ids  = aws_security_group.this.*.id
  private_dns_enabled = true
}

resource "aws_api_gateway_rest_api_policy" "this" {
  count       = var.private != null ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "execute-api:Invoke",
        Resource = "arn:aws:execute-api:${var.aws_region}:${local.account_id}:${aws_api_gateway_rest_api.this.id}/*"
        Condition = {
          StringEquals = {
            "aws:SourceVpc" = var.private.vpc
          }
        }
      }
    ]
  })
}

resource "aws_api_gateway_domain_name" "this" {
  domain_name     = local.custom_domain
  certificate_arn = var.domain.certificate_arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Principal = "*"
        Action   = "execute-api:Invoke"
        Resource = "arn:aws:execute-api:${var.aws_region}:${local.account_id}:/domainnames/*"

        Condition = {
          StringEquals = {
            "aws:SourceVpc" = var.private.vpc
          }
        }
      }
    ]
  })

  endpoint_configuration {
    types = local.endpoint_types
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this.domain_name
  domain_name_id = aws_api_gateway_domain_name.this.domain_name_id
}

resource "aws_api_gateway_domain_name_access_association" "this" {
  count                          = var.private != null ? 1 : 0
  access_association_source      = aws_vpc_endpoint.this[0].id
  access_association_source_type = "VPCE"
  domain_name_arn                = aws_api_gateway_domain_name.this.arn
}

resource "aws_route53_record" "this" {
  zone_id = var.domain.zone.id
  name    = local.custom_domain
  type    = "A"

  alias {
    name                   = aws_vpc_endpoint.this[0].dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.this[0].dns_entry[0].hosted_zone_id
    evaluate_target_health = false
  }
}

output "paths" {
  value = local.paths
}

output "permissions" {
  value = local.permissions
}
