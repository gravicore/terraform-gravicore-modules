
# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "appsync" {
  description = "required. AppSync API to attach resolvers"
  type = object({
    id = string
  })
}

variable "resolvers" {
  description = "optional. List of resolvers to attach to the AppSync API"
  type = list(object({
    field = string
    type  = string
    target = object({
      arn  = optional(string)
      role = optional(string)
      type = optional(string)
    })
    template = object({
      req = optional(string)
      res = optional(string)
    })
  }))
  default = []
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
locals {
  datasource_types = {
    none   = "NONE"
    lambda = "AWS_LAMBDA"
  }

  resolvers = var.resolvers == null ? [] : [
    for r in var.resolvers : {
      field     = r.field
      type      = r.type
      is_lambda = r.target.type == "lambda"
      name      = lower(join("_", regexall("[a-zA-Z0-9]+", "${local.module_prefix}_${coalesce(r.target.type, "none")}_${r.type}_${r.field}")))
      target = {
        arn  = r.target.arn
        role = r.target.role
        type = local.datasource_types[coalesce(r.target.type, "none")]
      }
      template = {
        req = coalesce(r.template.req, file("${path.module}/templates/req.vtl"))
        res = coalesce(r.template.res, file("${path.module}/templates/res.vtl"))
      }
    }
  ]
}

resource "aws_appsync_datasource" "this" {
  count            = var.create ? length(local.resolvers) : 0
  api_id           = var.appsync.id
  name             = local.resolvers[count.index].name
  type             = local.resolvers[count.index].target.type
  service_role_arn = local.resolvers[count.index].target.role

  dynamic "lambda_config" {
    for_each = local.resolvers[count.index].is_lambda ? [1] : []
    content {
      function_arn = local.resolvers[count.index].target.arn
    }
  }
}

resource "aws_appsync_resolver" "this" {
  count       = var.create ? length(local.resolvers) : 0
  api_id      = var.appsync.id
  field       = local.resolvers[count.index].field
  type        = local.resolvers[count.index].type
  data_source = aws_appsync_datasource.this[count.index].name

  request_template  = local.resolvers[count.index].template.req
  response_template = local.resolvers[count.index].template.res
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "datasources" {
  description = "List of AppSync datasources"
  value       = aws_appsync_datasource.this.*.id
}

output "resolvers" {
  description = "List of AppSync resolvers"
  value       = aws_appsync_resolver.this.*.id
}
