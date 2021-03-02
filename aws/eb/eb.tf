# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "solution_stack_name" {
  default     = "64bit Amazon Linux 2018.03 v2.12.14 running Docker 18.06.1-ce"
  type        = string
  description = "(Optional) A solution stack to base your environment off of. Example stacks can be found in the Amazon API documentation(https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html)"
}

variable logs_stream_logs {
  type        = string
  default     = "true"
  description = "Whether to create groups in CloudWatch Logs for proxy and deployment logs, and stream logs from each instance in your environment"
}

variable "logs_delete_on_terminate" {
  description = "Whether to delete the log groups when the environment is terminated. If false, the logs are kept logs_retention_in_days"
  default     = "true"
  type        = string
}

variable logs_retention_in_days {
  type        = string
  default     = "7"
  description = "The number of days to keep log events before they expire. Valid Values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653"
}

variable xray_enabled {
  type        = string
  default     = "true"
  description = "Set to true to run the X-Ray daemon on the instances in your environment"
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
  default     = null
  type        = string
  description = "The ID for your Amazon VPC"
}

variable "alb_subnets" {
  default     = null
  type        = list
  description = "The IDs of the subnet or subnets for the elastic load balancer. If you have multiple subnets, specify the value as a single comma-delimited string of subnet IDs"
}

variable "ec2_subnets" {
  default     = null
  type        = list
  description = "The IDs of the Auto Scaling group subnet or subnets. If you have multiple subnets, specify the value as a single comma-delimited string of subnet IDs"
}

variable "vpc_elb_scheme" {
  type        = string
  default     = "public"
  description = "Specify internal if you want to create an internal load balancer in your Amazon VPC so that your Elastic Beanstalk application cannot be accessed from outside your Amazon VPC. If you specify a value other than public or internal, Elastic Beanstalk will ignore the value"
}

variable "alb_security_group_ingress_cider" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks to apply to alb ingress rule"
}

variable "alb_security_group_egress_cider" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks to apply to alb egress rule"
}

variable "instances_instance_types" {
  type        = string
  default     = "t3.medium"
  description = "A comma-separated list of instance types you want your environment to use. For example: t2.micro,t3.micro"
}

variable "enable_dns" {
  type        = bool
  description = "Create Route53 DNS entry"
  default     = false
}

variable "dns_zone_id" {
  type        = string
  description = "(Required) The ID of the hosted zone to contain this record"
  default     = ""
}

variable "dns_zone_name" {
  type        = string
  description = "Route53 DNS Zone name"
  default     = ""
}

variable "dns_name_prefix" {
  type        = string
  description = "(Optional) Overwites the module name as the prefix of the DNS record Name"
  default     = ""
}

variable "type" {
  type        = string
  default     = "CNAME"
  description = "Type of DNS records to create"
}

variable "ttl" {
  type        = string
  default     = "60"
  description = "The TTL of the record to add to the DNS zone to complete certificate validation"
}

variable "https_redirect" {
  type        = bool
  default     = false
  description = "When ALB is used, this will create a listener to redirect http to https"
}

variable "app_healthcheck_url" {
  type        = string
  default     = ""
  description = "description"
}

variable "environmental_variables" {
  type        = map
  default     = {}
  description = "description"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "eb_ec2" {
  count = var.create ? 1 : 0
  name  = "${local.module_prefix}-ec2"

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

data "aws_iam_policy_document" "eb_ec2" {
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
  count = var.create ? 1 : 0
  name  = local.module_prefix
  role  = aws_iam_role.eb_ec2[0].id

  policy = data.aws_iam_policy_document.eb_ec2.json
}

resource "aws_iam_role_policy_attachment" "web_tier" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.eb_ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "worker_tier" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.eb_ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "elastic_beanstalk_multi_container_docker" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.eb_ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_elastic_beanstalk_application" "default" {
  count       = var.create ? 1 : 0
  name        = local.module_prefix
  description = var.app_description

  tags = "${merge(local.tags, map("Namespace", null))}"

  lifecycle {
    ignore_changes = [
      tags["Namespace"],
    ]
  }
}

resource "aws_iam_instance_profile" "eb_ec2" {
  count = var.create ? 1 : 0
  name  = "${local.module_prefix}-ec2"
  role  = "${aws_iam_role.eb_ec2[0].name}"
}

resource "aws_security_group" "eb_alb_sg" {
  count       = var.create ? 1 : 0
  name        = "${local.module_prefix}-alb-sg"
  description = "${var.desc_prefix} ALB Security Group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = var.default_process_port
    to_port     = var.default_process_port
    protocol    = "6"
    cidr_blocks = var.alb_security_group_ingress_cider
  }

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "6"
    cidr_blocks = var.alb_security_group_ingress_cider
  }

  egress {
    from_port   = var.default_process_port
    to_port     = var.default_process_port
    protocol    = "6"
    cidr_blocks = var.alb_security_group_egress_cider
  }

  tags = "${merge(local.tags, map("Name", "${local.module_prefix}-alb"))}"
}

resource "aws_elastic_beanstalk_environment" "default" {
  count               = var.create ? 1 : 0
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
    value     = aws_iam_instance_profile.eb_ec2[0].name
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

  dynamic "setting" {
    for_each = var.environmental_variables
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
    }
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = var.logs_stream_logs
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = var.logs_delete_on_terminate
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = var.logs_retention_in_days
  }

  setting {
    namespace = "aws:elasticbeanstalk:xray"
    name      = "XRayEnabled"
    value     = var.xray_enabled
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
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = var.vpc_elb_scheme
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = var.instances_instance_types
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = var.app_healthcheck_url
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
    value     = aws_security_group.eb_alb_sg[0].id
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = aws_security_group.eb_alb_sg[0].id
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
  count             = var.create && var.https_redirect ? 1 : 0
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

resource "aws_route53_record" "default" {
  count   = var.create && var.enable_dns ? 1 : 0
  zone_id = var.dns_zone_id
  name    = join(".", [coalesce(var.dns_name_prefix, var.name), var.dns_zone_name])
  type    = var.type
  ttl     = var.ttl
  records = [aws_elastic_beanstalk_environment.default[0].cname]

}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "beanstalk_env_cname" {
  description = "CNAME of beanstalk enviroment"
  value       = "${aws_elastic_beanstalk_environment.default[0].cname}"
}

output "beanstalk_dns_fqdn" {
  description = "FQDN that points to the beanstalk environment"
  value       = "${aws_route53_record.default[0].fqdn}"
}

output "beanstalk_load_balancer" {
  value = "${aws_elastic_beanstalk_environment.default[0].load_balancers}"
}
