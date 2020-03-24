# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "solution_stack_name" {
  default = "64bit Amazon Linux 2018.03 v2.12.14 running Docker 18.06.1-ce"
  type    = string
}

variable "env_port_value" {
  description = "The value to set for the Enviroment variable PORT"
  default     = "80"
  type        = string
}

variable "logs_delete_on_terminate" {
  description = "Delete cloudwatch logs on termination of beanstalk env"
  default     = "true"
  type        = string
}

variable "app_description" {
  description = "(Optional) Short description of the application"
  default     = ""
  type        = string
}

variable "asg_min_size" {
  type        = number
  default     = 1
  description = "Minimum number of instances you want in your Auto Scaling group"
}

variable "asg_max_size" {
  type        = number
  default     = 1
  description = "Maximum number of instances you want in your Auto Scaling group"
}

variable "asg_availability_zones" {
  type        = string
  default     = "any"
  description = "Availability Zones (AZs) are distinct locations within a region that are engineered to be isolated from failures in other AZs and provide inexpensive, low-latency network connectivity to other AZs in the same region. Choose the number of AZs for your instances"
}

variable "environment_environment_type" {
  type        = string
  default     = "LoadBalanced"
  description = "Set to SingleInstance to launch one EC2 instance with no load balancer."
}

variable "environment_load_balancer_type" {
  type        = string
  default     = "application"
  description = "The type of load balancer for your environment"
}

variable "alb_cert" {
  description = "Certificate attached to ALB"
  default     = null
  type        = string
}

variable "default_process_port" {
  type        = number
  default     = 80
  description = "Port on which the process listens"
}

variable "launchconfiguration_ec2_key_name" {
  type        = string
  default     = null
  description = "A key pair enables you to securely log into your EC2 instance"
}

variable "default_process_protocol" {
  type        = string
  default     = "HTTP"
  description = "Protocol that the process uses. With an application load balancer, you can only set this option to HTTP or HTTPS. With a network load balancer, you can only set this option to TCP."
}

variable "vpc_id" {
  default = null
  type    = string
}

variable "alb_subnets" {
  default = null
  type    = list
}

variable "ec2_subnets" {
  default = null
  type    = list
}

variable "instances_instance_types" {
  type        = string
  default     = "t3.medium"
  description = "A comma-separated list of instance types you want your environment to use. For example: t2.micro,t3.micro"
}

variable "aliases" {
  type        = list(string)
  description = "List of FQDN's - Used to set the Alternate Domain Names (CNAMEs) setting on Cloudfront"
  default     = []
}

variable "parent_zone_id" {
  type        = string
  default     = null
  description = "ID of the hosted zone to contain this record  (or specify `parent_zone_name`)"
}

variable "parent_zone_name" {
  type        = string
  default     = null
  description = "Name of the hosted zone to contain this record (or specify `parent_zone_id`)"
}

variable "https_redirect" {
  type        = bool
  default     = false
  description = "When ALB is used, this will create a listener to redirect http to https"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "ec2" {
  count  = var.create ? 1 : 0
  name    = "${local.module_prefix}-ec2"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
  EOF
}

data "aws_iam_policy_document" "ec2" {
  statement {
    sid = ""

    actions = [
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetHealth",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:GetConsoleOutput",
      "ec2:AssociateAddress",
      "ec2:DescribeAddresses",
      "ec2:DescribeSecurityGroups",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeNotificationConfigurations",
    ]

    resources = ["*"]

    effect = "Allow"
  }

  statement {
    sid = "AllowOperations"

    actions = [
      "autoscaling:AttachInstances",
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:CreateLaunchConfiguration",
      "autoscaling:DeleteLaunchConfiguration",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:DeleteScheduledAction",
      "autoscaling:DescribeAccountLimits",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeLoadBalancers",
      "autoscaling:DescribeNotificationConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeScheduledActions",
      "autoscaling:DetachInstances",
      "autoscaling:PutScheduledUpdateGroupAction",
      "autoscaling:ResumeProcesses",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:SuspendProcesses",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "cloudwatch:PutMetricAlarm",
      "ec2:AssociateAddress",
      "ec2:AllocateAddress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DisassociateAddress",
      "ec2:ReleaseAddress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:TerminateInstances",
      "ecs:CreateCluster",
      "ecs:DeleteCluster",
      "ecs:DescribeClusters",
      "ecs:RegisterTaskDefinition",
      "elasticbeanstalk:*",
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "iam:ListRoles",
      "iam:PassRole",
      "logs:CreateLogGroup",
      "logs:PutRetentionPolicy",
      "rds:DescribeDBEngineVersions",
      "rds:DescribeDBInstances",
      "rds:DescribeOrderableDBInstanceOptions",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:ListBucket",
      "sns:CreateTopic",
      "sns:GetTopicAttributes",
      "sns:ListSubscriptionsByTopic",
      "sns:Subscribe",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "codebuild:CreateProject",
      "codebuild:DeleteProject",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]

    effect = "Allow"
  }

  statement {
    sid = "AllowS3OperationsOnElasticBeanstalkBuckets"

    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::*",
    ]

    effect = "Allow"
  }

  statement {
    sid = "AllowDeleteCloudwatchLogGroups"

    actions = [
      "logs:DeleteLogGroup",
    ]

    resources = [
      "arn:aws:logs:*:*:log-group:/aws/elasticbeanstalk*",
    ]

    effect = "Allow"
  }

  statement {
    sid = "AllowCloudformationOperationsOnElasticBeanstalkStacks"

    actions = [
      "cloudformation:*",
    ]

    resources = [
      "arn:aws:cloudformation:*:*:stack/awseb-*",
      "arn:aws:cloudformation:*:*:stack/eb-*",
    ]

    effect = "Allow"
  }
}

resource "aws_iam_role_policy" "default" {
  count  = var.create ? 1 : 0
  name    = local.module_prefix
  role    = aws_iam_role.ec2[0].id

  policy = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_role_policy_attachment" "web-tier" {
  count     = var.create ? 1 : 0
  role       = aws_iam_role.ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "worker-tier" {
  count     = var.create ? 1 : 0
  role       = aws_iam_role.ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "elastic_beanstalk_multi_container_docker" {
  count     = var.create ? 1 : 0
  role       = aws_iam_role.ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_elastic_beanstalk_application" "default" {
  count      = var.create ? 1 : 0
  name        = local.module_prefix
  description = var.app_description

  tags = "${merge(local.tags, map("Namespace", null))}"

  lifecycle {
    ignore_changes = [
      tags["Namespace"],
    ]
  }
}

resource "aws_iam_instance_profile" "ec2" {
  count  = var.create ? 1 : 0
  name    = "${local.module_prefix}-ec2"
  role    = "${aws_iam_role.ec2[0].name}"
}

resource "aws_security_group" "alb_sg" {
  count      = var.create ? 1 : 0
  name        = "${local.module_prefix}-alb-sg"
  description = "${var.desc_prefix} ALB Security Group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = var.default_process_port
    to_port     = var.default_process_port
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = var.default_process_port
    to_port     = var.default_process_port
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(local.tags, map("Name", "${local.module_prefix}-alb"))}"
}

resource "aws_elastic_beanstalk_environment" "default" {
  count              = var.create ? 1 : 0
  name                = "${local.module_prefix}"
  application         = "${aws_elastic_beanstalk_application.default[0].name}"
  solution_stack_name = "${var.solution_stack_name}"

  tags = "${merge(
    local.technical_tags,
    local.automation_tags,
    local.security_tags,
    var.tags,
    map("Environment", "${var.environment}")
  )}"

  wait_for_ready_timeout = "10m"

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = var.asg_min_size
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = var.asg_max_size
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "Availability Zones"
    value     = var.asg_availability_zones
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2[0].name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = var.launchconfiguration_ec2_key_name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"

    value = var.environment_environment_type
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = var.environment_load_balancer_type
  }

  # setting {
  #   namespace = "aws:elasticbeanstalk:application:environment"
  #   name      = "PORT"
  #   value     = "${var.env_port_value}"
  # }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
    name      = "HealthStreamingEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = var.logs_delete_on_terminate
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "7"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", var.ec2_subnets)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", var.alb_subnets)
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = var.instances_instance_types
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = var.default_process_port
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = var.default_process_protocol
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "ManagedSecurityGroup"
    value     = aws_security_group.alb_sg[0].id
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = aws_security_group.alb_sg[0].id
  }

  setting {
    namespace = "aws:elbv2:listener:default"
    name      = "ListenerEnabled"
    value     = "false"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "ListenerEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = var.alb_cert
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLPolicy"
    value     = "ELBSecurityPolicy-2016-08"
  }
}

resource "aws_lb_listener" "https_redirect" {
  count            = var.create && var.https_redirect ? 1 : 0
  load_balancer_arn = "${join(",", aws_elastic_beanstalk_environment.default[0].load_balancers)}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }

    type = "redirect"
  }
}

# module "dns" {
#   source           = "git::https://github.com/cloudposse/terraform-aws-route53-alias.git?ref=tags/0.3.0"
#   enabled          = var.create && length(var.parent_zone_id) > 0 || length(var.parent_zone_name) > 0 ? true : false
#   aliases          = var.aliases
#   parent_zone_id   = var.parent_zone_id
#   parent_zone_name = var.parent_zone_name
#   target_dns_name  = aws_cloudfront_distribution.default.domain_name
#   target_zone_id   = aws_cloudfront_distribution.default.hosted_zone_id
# }

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "beanstalk_env_cname" {
  description = "CNAME of beanstalk enviroment"
  value       = "${aws_elastic_beanstalk_environment.default[0].cname}"
}

output "beanstalk_load_balancer" {
  value = "${aws_elastic_beanstalk_environment.default[0].load_balancers}"
}
