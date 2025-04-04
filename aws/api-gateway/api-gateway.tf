# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "authorizers" {
  type        = map(any)
  default     = {}
  description = "The authorizers to use for the API Gateway. The key is the type of the authorizer and the value is the configuaration. Supported types are 'cognito'."
}

variable "private" {
  type = object({
    vpc     = string
    subnets = list(string)
    cidrs   = optional(list(string), ["0.0.0.0/0"])
  })
  default     = null
  description = "The VPC and subnets to use for the API Gateway. If not provided, the API Gateway will be public."
}

variable "domain" {
  type = object({
    id   = string
    name = string
    ssl  = string
  })
  default     = null
  description = "The domain name and SSL certificate to use for the API Gateway. If not provided, the API Gateway will have only the stage domain."
}

variable "paths" {
  type = map(map(object({
    lambda      = optional(string, "")
    authorizers = optional(list(string), [])
  })))
  default     = {}
  description = "The paths to use for the API Gateway. The key is the path and the value is the configuration. The configuration is a map with the following keys: 'lambda' (the ARN of the Lambda function to invoke) and 'authorizers' (a list of authorizers to use for the path)."
}

variable "throttle" {
  type = object({
    rate  = optional(number, 10)
    burst = optional(number, 20)
  })
  default     = {}
  description = "The throttle settings for the API Gateway. The default is 10 requests per second and 20 burst capacity."
}

variable "timeout" {
  type        = number
  default     = 29
  description = "The timeout for the API Gateway in seconds. The default is 29 seconds."
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
locals {
  counts = {
    default = var.create ? 1 : 0
    domain  = var.create && var.domain != null ? 1 : 0
    private = var.create && var.private != null ? 1 : 0
  }

  permissions = toset(local.counts.default == 1 ? flatten(flatten(
    [for pk, pv in var.paths :
      [for mk, mv in pv : mv.lambda]
    ]
  )) : [])

  cognito = var.authorizers.cognito == null ? {} : {
    "${local.module_prefix}-cognito" = {
      type = "apiKey"
      in   = "header"
      name = "Authorization"

      x-amazon-apigateway-authtype = "cognito_user_pools"
      x-amazon-apigateway-authorizer = {
        type         = "cognito_user_pools"
        providerARNs = ["arn:aws:cognito-idp:${var.aws_region}:${local.account_id}:userpool/${var.authorizers.cognito}"]
      }
    }
  }

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
          uri                 = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${mv.lambda}/invocations"
          httpMethod          = "POST"
          type                = "aws_proxy"
          passthroughBehavior = "when_no_match"
          timeoutInMillis     = var.timeout * 1000
        }
      }
    }
  }
}

resource "aws_api_gateway_rest_api" "this" {
  count = local.counts.default
  tags  = local.tags
  name  = local.module_prefix
  body = var.paths != {} ? jsonencode({
    openapi = "3.0.1"
    info = {
      title   = local.module_prefix
      version = "1.0"
    }
    paths = local.paths
    components = {
      securitySchemes = merge({}, local.cognito)
    }
  }) : null

  endpoint_configuration {
    types            = local.counts.private == 1 ? ["PRIVATE"] : ["REGIONAL"]
    vpc_endpoint_ids = local.counts.private == 1 ? aws_vpc_endpoint.this.*.id : null
  }
}

resource "aws_lambda_permission" "this" {
  for_each      = local.permissions
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${concat(aws_api_gateway_rest_api.this.*.execution_arn, [""])[0]}/*/*/*"
}

resource "aws_api_gateway_deployment" "this" {
  count       = local.counts.default
  rest_api_id = concat(aws_api_gateway_rest_api.this.*.id, [""])[0]

  triggers = {
    redeployment = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_rest_api_policy.this]
}

resource "aws_api_gateway_stage" "this" {
  count         = local.counts.default
  tags          = local.tags
  deployment_id = concat(aws_api_gateway_deployment.this.*.id, [""])[0]
  rest_api_id   = concat(aws_api_gateway_rest_api.this.*.id, [""])[0]
  stage_name    = var.stage
}

resource "aws_api_gateway_method_settings" "this" {
  count       = local.counts.default
  rest_api_id = concat(aws_api_gateway_rest_api.this.*.id, [""])[0]
  stage_name  = concat(aws_api_gateway_stage.this.*.stage_name, [""])[0]
  method_path = "*/*"

  dynamic "settings" {
    for_each = var.throttle != null ? [1] : []
    content {
      metrics_enabled        = true
      throttling_burst_limit = var.throttle.burst
      throttling_rate_limit  = var.throttle.rate
    }
  }
}

resource "aws_security_group" "this" {
  count  = local.counts.private
  tags   = local.tags
  vpc_id = var.private.vpc

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = var.private.cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "this" {
  count               = local.counts.private
  tags                = local.tags
  vpc_id              = var.private.vpc
  service_name        = "com.amazonaws.${var.aws_region}.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private.subnets
  security_group_ids  = aws_security_group.this.*.id
  private_dns_enabled = true
}

resource "aws_api_gateway_rest_api_policy" "this" {
  count       = local.counts.private
  rest_api_id = concat(aws_api_gateway_rest_api.this.*.id, [""])[0]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "execute-api:Invoke",
        Resource  = "arn:aws:execute-api:${var.aws_region}:${local.account_id}:${concat(aws_api_gateway_rest_api.this.*.id, [""])[0]}/*"
        Condition = {
          IpAddress = {
            "aws:VpcSourceIp" = var.private.cidrs
          }
        }
      }
    ]
  })
}

resource "aws_api_gateway_domain_name" "this" {
  count           = local.counts.domain
  tags            = local.tags
  domain_name     = "${var.name}.${var.domain.name}"
  certificate_arn = var.domain.ssl

  policy = local.counts.private == 1 ? jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "arn:aws:execute-api:${var.aws_region}:${local.account_id}:/domainnames/*"
        Condition = {
          IpAddress = {
            "aws:VpcSourceIp" = var.private.cidrs
          }
        }
      }
    ]
  }) : null

  dynamic "endpoint_configuration" {
    for_each = local.counts.private == 1 ? [1] : []
    content {
      types = ["PRIVATE"]
    }
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  count          = local.counts.domain
  api_id         = concat(aws_api_gateway_rest_api.this.*.id, [""])[0]
  stage_name     = concat(aws_api_gateway_stage.this.*.stage_name, [""])[0]
  domain_name    = concat(aws_api_gateway_domain_name.this.*.domain_name, [""])[0]
  domain_name_id = concat(aws_api_gateway_domain_name.this.*.domain_name_id, [""])[0]
}

resource "aws_api_gateway_domain_name_access_association" "this" {
  count                          = var.private != null ? local.counts.domain : 0
  tags                           = local.tags
  access_association_source      = concat(aws_vpc_endpoint.this.*.id, [""])[0]
  access_association_source_type = "VPCE"
  domain_name_arn                = concat(aws_api_gateway_domain_name.this.*.arn, [""])[0]
}

resource "aws_route53_record" "this" {
  count   = local.counts.domain
  zone_id = var.domain.id
  name    = concat(aws_api_gateway_domain_name.this.*.domain_name, [""])[0]
  type    = "A"

  alias {
    name = try(try(
      aws_vpc_endpoint.this[0].dns_entry[0].dns_name,
      aws_api_gateway_domain_name.this[0].cloudfront_domain_name
    ), "")
    zone_id = try(try(
      aws_vpc_endpoint.this[0].dns_entry[0].hosted_zone_id,
      aws_api_gateway_domain_name.this[0].cloudfront_zone_id
    ), "")
    evaluate_target_health = false
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

locals {
  api_id     = concat(aws_api_gateway_rest_api.this.*.id, [""])[0]
  vpce_id    = concat(aws_vpc_endpoint.this.*.id, [""])[0]
  invoke_url = concat(aws_api_gateway_stage.this.*.invoke_url, [""])[0]
}

output "api-gateway" {
  value = {
    authorizers = [for k, v in var.authorizers : k]
    domain_url  = "https://${concat(aws_api_gateway_domain_name.this.*.domain_name, [""])[0]}"
    id          = local.api_id
    invoke_url  = local.invoke_url
    paths       = local.paths
    private     = local.counts.private == 1
    private_url = local.counts.private == 1 ? replace(local.invoke_url, local.api_id, "${local.api_id}-${local.vpce_id}") : null
    throttle    = var.throttle
    vpce_id     = local.vpce_id
  }
  description = "The API Gateway outputs"
}
