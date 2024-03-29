# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  type        = string
  description = "VPC ID to associate with ALB"
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs to associate with ALB"
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "A list of additional security group IDs to allow access to ALB"
}

variable "internal" {
  type        = bool
  default     = false
  description = "A bool flag to determine whether the ALB should be internal"
}

variable "http_redirect_enabled" {
  type        = bool
  default     = true
  description = "A bool flag to enable/disable HTTP listener"
}

variable "http_ingress_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/8"]
  description = "List of CIDR blocks to allow in HTTP security group"
}

variable "http_ingress_prefix_list_ids" {
  type        = list(string)
  default     = []
  description = "List of prefix list IDs for allowing access to HTTP ingress security group"
}

variable "domain_name" {
  type        = string
  default     = ""
  description = ""
}

variable "dns_zone_id" {
  type        = string
  default     = ""
  description = ""
}

variable "dns_zone_name" {
  type        = string
  default     = ""
  description = ""
}

variable "certificate_arn" {
  type        = string
  default     = ""
  description = "The ARN of the default SSL certificate for HTTPS listener"
}

variable "https_ports" {
  type        = list(number)
  default     = [443]
  description = "The port for the HTTPS listener"
}

variable "https_enabled" {
  type        = bool
  default     = false
  description = "A bool flag to enable/disable HTTPS listener"
}

variable "https_ingress_cidr_blocks" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks to allow in HTTPS security group"
}

variable "https_ingress_prefix_list_ids" {
  type        = list(string)
  default     = []
  description = "List of prefix list IDs for allowing access to HTTPS ingress security group"
}

variable "https_ssl_policy" {
  description = "The name of the SSL Policy for the listener."
  default     = "ELBSecurityPolicy-2015-05"
}

variable "access_logs_prefix" {
  type        = string
  default     = null
  description = "The S3 bucket prefix"
}

variable "access_logs_enabled" {
  type        = bool
  default     = true
  description = "A bool flag to enable/disable access_logs"
}

variable "access_logs_region" {
  type        = string
  default     = null
  description = "The region for the access_logs S3 bucket"
}

variable "alb_access_logs_s3_bucket_force_destroy" {
  description = "A bool that indicates all objects should be deleted from the ALB access logs S3 bucket so that the bucket can be destroyed without error"
  default     = false
}

variable "cross_zone_load_balancing_enabled" {
  type        = bool
  default     = true
  description = "A bool flag to enable/disable cross zone load balancing"
}

variable "http2_enabled" {
  type        = bool
  default     = true
  description = "A bool flag to enable/disable HTTP/2"
}

variable "idle_timeout" {
  type        = number
  default     = 60
  description = "The time in seconds that the connection is allowed to be idle"
}

variable "ip_address_type" {
  type        = string
  default     = "ipv4"
  description = "The type of IP addresses used by the subnets for your load balancer. The possible values are `ipv4` and `dualstack`."
}

variable "deletion_protection_enabled" {
  type        = bool
  default     = false
  description = "A bool flag to enable/disable deletion protection for ALB"
}

variable "drop_invalid_header_fields" {
  type        = bool
  default     = true
  description = "A bool flag to enable/disable dropping invalid header fields"
}

variable "target_groups" {
  type = list(any)
  default = [{
    target_type          = "instance"
    protocol             = "HTTP"
    port                 = 80
    deregistration_delay = 15
    health_check = {
      enabled             = true
      path                = "/"
      protocol            = "HTTP"
      port                = 80
      interval            = 15
      timeout             = 10
      healthy_threshold   = 2
      unhealthy_threshold = 2
      matcher             = "200-399"
    }
    stickiness = {
      type            = "lb_cookie"
      cookie_duration = "604800"
      enabled         = false
    }
  }]
  description = "A list of target group resources"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  count       = var.create ? 1 : 0
  name        = local.module_prefix
  tags        = local.tags
  description = "Controls access to the ALB (HTTP/HTTPS)"

  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "egress" {
  count = var.create ? 1 : 0

  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = concat(aws_security_group.alb.*.id, [""])[0]
}

resource "aws_security_group_rule" "alb_http_ingress" {
  count = var.create ? var.http_redirect_enabled ? 1 : length(var.target_groups) : 0

  type              = "ingress"
  from_port         = var.http_redirect_enabled ? 80 : var.target_groups[count.index].port
  to_port           = var.http_redirect_enabled ? 80 : var.target_groups[count.index].port
  protocol          = "tcp"
  cidr_blocks       = var.http_ingress_cidr_blocks
  prefix_list_ids   = var.http_ingress_prefix_list_ids
  security_group_id = concat(aws_security_group.alb.*.id, [""])[0]
}

resource "aws_security_group_rule" "alb_https_ingress" {
  count = var.create ? length(var.https_ports) : 0

  type              = "ingress"
  from_port         = var.https_ports[count.index]
  to_port           = var.https_ports[count.index]
  protocol          = "tcp"
  cidr_blocks       = var.https_ingress_cidr_blocks
  prefix_list_ids   = var.https_ingress_prefix_list_ids
  security_group_id = concat(aws_security_group.alb.*.id, [""])[0]
}

resource "aws_lb" "alb" {
  count = var.create ? 1 : 0
  name  = local.module_prefix
  tags  = local.tags

  load_balancer_type = "application"
  internal           = var.internal
  security_groups = compact(
    concat(var.security_group_ids, [concat(aws_security_group.alb.*.id, [""])[0]]),
  )
  subnets                          = var.subnet_ids
  enable_cross_zone_load_balancing = var.cross_zone_load_balancing_enabled
  enable_http2                     = var.http2_enabled
  idle_timeout                     = var.idle_timeout
  ip_address_type                  = var.ip_address_type
  enable_deletion_protection       = var.deletion_protection_enabled
  drop_invalid_header_fields       = var.drop_invalid_header_fields
  access_logs {
    bucket  = join("", aws_s3_bucket.default.*.id)
    prefix  = var.access_logs_prefix
    enabled = var.access_logs_enabled
  }
}

resource "aws_lb_target_group" "alb" {
  count = var.create ? length(var.target_groups) : 0
  name  = lower(join("-", [local.module_prefix, var.target_groups[count.index].protocol, var.target_groups[count.index].port]))
  tags  = local.tags

  vpc_id               = var.vpc_id
  port                 = var.target_groups[count.index].port
  protocol             = var.target_groups[count.index].protocol
  target_type          = var.target_groups[count.index].target_type
  deregistration_delay = var.target_groups[count.index].deregistration_delay
  health_check {
    enabled             = var.target_groups[count.index].health_check.enabled
    path                = var.target_groups[count.index].health_check.path
    protocol            = var.target_groups[count.index].protocol
    timeout             = var.target_groups[count.index].health_check.timeout
    healthy_threshold   = var.target_groups[count.index].health_check.healthy_threshold
    unhealthy_threshold = var.target_groups[count.index].health_check.unhealthy_threshold
    interval            = var.target_groups[count.index].health_check.interval
    matcher             = var.target_groups[count.index].health_check.matcher
  }

  dynamic "stickiness" {
    for_each = lookup(var.target_groups[count.index], "stickiness", null) == null ? [] : [var.target_groups[count.index].stickiness]
    content {
      type            = stickiness.value["type"]
      cookie_duration = stickiness.value["cookie_duration"]
      enabled         = stickiness.value["enabled"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  count = var.create ? var.http_redirect_enabled ? 1 : length(var.target_groups) : 0

  load_balancer_arn = concat(aws_lb.alb.*.arn, [""])[0]
  port              = var.http_redirect_enabled ? 80 : var.target_groups[count.index].port
  protocol          = "HTTP"
  default_action {
    type             = var.http_redirect_enabled ? "redirect" : "forward"
    target_group_arn = var.http_redirect_enabled ? "" : aws_lb_target_group.alb[count.index].arn
    dynamic "redirect" {
      for_each = var.http_redirect_enabled ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.create && var.https_enabled ? length(var.https_ports) : 0
  load_balancer_arn = concat(aws_lb.alb.*.arn, [""])[0]

  port            = var.https_ports[count.index]
  protocol        = "HTTPS"
  ssl_policy      = var.https_ssl_policy
  certificate_arn = var.certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.alb[count.index].arn
    type             = "forward"
  }
}

resource "aws_route53_record" "alb" {
  count = var.create && var.dns_zone_id != "" && var.dns_zone_name != "" ? 1 : 0

  zone_id         = var.dns_zone_id
  name            = coalesce(var.domain_name, join(".", [var.name, var.dns_zone_name]))
  type            = "CNAME"
  ttl             = 30
  records         = [concat(aws_lb.alb.*.dns_name, [""])[0]]
  allow_overwrite = true
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "alb_name" {
  description = "The ARN suffix of the ALB"
  value       = concat(aws_lb.alb.*.name, [""])[0]
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = concat(aws_lb.alb.*.arn, [""])[0]
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the ALB"
  value       = concat(aws_lb.alb.*.arn_suffix, [""])[0]
}

output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = concat(aws_lb.alb.*.dns_name, [""])[0]
}

output "alb_zone_id" {
  description = "The ID of the zone which ALB is provisioned"
  value       = concat(aws_lb.alb.*.zone_id, [""])[0]
}

output "security_group_ids" {
  description = "The security group IDs of the ALB"
  value       = aws_security_group.alb.*.id
}

output "target_group_arns" {
  description = "The target group ARNs"
  value       = aws_lb_target_group.alb.*.arn
}

output "http_listener_arns" {
  description = "The ARNs of the HTTP listeners"
  value       = aws_lb_listener.http.*.arn
}

output "https_listener_arns" {
  description = "The ARNs of the HTTPS listeners"
  value       = aws_lb_listener.https.*.arn
}

output "listener_arns" {
  description = "A list of all the listener ARNs"
  value = compact(
    concat(aws_lb_listener.http.*.arn, aws_lb_listener.https.*.arn),
  )
}

output "route53_dns_name" {
  description = "DNS name of Route53"
  value       = length(aws_route53_record.alb) == 1 ? aws_route53_record.alb[0].name : ""
}
