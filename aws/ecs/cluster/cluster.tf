# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "task" {
  description = "the configuration shared by all tasks in the cluster"
  type = object({
    certificate_arn = optional(string, "")
    datadog = optional(object({
      ssm_key     = string
      enable_log  = optional(bool, true)
      enable_apm  = optional(bool, false)
      environment = optional(map(string), {})
    }), null)
    execution_role_arn = optional(string, "")
    task_role_arn      = optional(string, "")
    security_group_ids = optional(list(string), [])
    subnet_ids = optional(object({
      private = optional(list(string), [])
      public  = optional(list(string), [])
    }), {})
    vpc_id    = optional(string, "")
    zone_id   = optional(string, "")
    zone_name = optional(string, "")
  })
  default = {}
}

variable "capacity" {
  description = "the configuration used to create capacity providers on ec2"
  type = map(object({
    instance = string
  }))
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
  capacity_providers = concat(["FARGATE"], [for key, value in module.capacity_providers : value.name])
  depends_on         = [aws_ecs_cluster.this]
}

module "capacity_providers" {
  for_each     = var.create ? var.capacity : {}
  source       = "./modules/capacity_provider"
  cluster_name = concat(aws_ecs_cluster.this.*.name, [""])[0]
  instance     = each.value.instance
  name         = each.key
  task         = var.task
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
