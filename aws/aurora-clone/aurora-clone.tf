# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------


variable "cluster_identifier" {
  type        = string
  description = "The name of the cluster to create"
}


variable "source_cluster_identifier" {
  type        = string
  description = "The name of the cluster to clone"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_rds_cluster" "default" {
  engine             = "aurora-postgresql"
  cluster_identifier = var.cluster_identifier
  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
  restore_to_point_in_time {
    source_cluster_identifier  = var.source_cluster_identifier
    restore_type               = "copy-on-write"
    use_latest_restorable_time = true
  }

}

resource "aws_rds_cluster_instance" "cluster_instances" {

  identifier         = "aurora-cluster-demo-instance-1"
  cluster_identifier = aws_rds_cluster.default.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.default.engine
  engine_version     = aws_rds_cluster.default.engine_version
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------


output "cluster_endpoint" {
  description = "The connection endpoint for the Aurora cluster."
  value       = aws_rds_cluster.default.endpoint
}
