# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "task" {
  description = "the configuration shared by all tasks in the cluster"
  type = object({
    certificate_arn    = optional(string, "")
    execution_role_arn = optional(string, "")
    role_arn           = optional(string, "")
    security_group_ids = optional(list(string), [])
    subnet_ids         = optional(list(string), [])
    vpc_id             = optional(string, "")
    zone_id            = optional(string, "")
    zone_name          = optional(string, "")
  })
  default = {}
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_cluster" "this" {
  count = var.create ? 1 : 0
  name  = local.module_prefix
  tags  = local.tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count              = var.create ? 1 : 0
  cluster_name       = local.module_prefix
  capacity_providers = ["FARGATE"]
  depends_on         = [aws_ecs_cluster.this]
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "name" {
  value = concat(aws_ecs_cluster.this.*.name, [""])[0]
}

output "task" {
  value = var.task
}
