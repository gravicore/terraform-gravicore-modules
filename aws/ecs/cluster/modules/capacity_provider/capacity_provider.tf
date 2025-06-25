# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------
variable "cluster_name" {}
variable "instance" {}
variable "name" {}
variable "task" {}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
locals {
  name = "${var.cluster_name}-${var.name}"
}

data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

resource "aws_iam_role" "this" {
  name = local.name
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "this" {
  name = local.name
  role = aws_iam_role.this.name
}

resource "aws_launch_template" "this" {
  name                   = local.name
  image_id               = data.aws_ami.this.id
  instance_type          = var.instance
  vpc_security_group_ids = var.task.security_group_ids

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = local.name
    }
  }

  user_data = base64encode(
    templatefile("${path.module}/ec2.tpl.sh", {
      CLUSTER_NAME = var.cluster_name
  }))
}

resource "aws_autoscaling_group" "this" {
  name                      = local.name
  vpc_zone_identifier       = var.task.subnet_ids["private"]
  desired_capacity          = 0
  max_size                  = 5
  min_size                  = 0
  default_instance_warmup   = 60
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "this" {
  name = local.name

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.this.arn

    managed_scaling {
      instance_warmup_period    = 60
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "arn" {
  value = aws_ecs_capacity_provider.this.arn
}

output "name" {
  value = aws_ecs_capacity_provider.this.name
}
