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

variable "internal" {
  type        = bool
  default     = false
  description = "A bool flag to determine whether the ALB should be internal"
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

variable "target_groups" {
  type = list(any)
  default = [{
    target_type          = "instance"
    protocol             = "TCP"
    port                 = 80
    deregistration_delay = 15
    health_check = {
      enabled             = true
      protocol            = "TCP"
      port                = 80
      interval            = 10
      healthy_threshold   = 2
      unhealthy_threshold = 2
    }
  }]
  description = "A list of target group resources"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "nlb" {
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
  security_group_id = aws_security_group.nlb[0].id
}

resource "aws_security_group_rule" "nlb_http_ingress" {
  count = var.create && length(var.target_groups) > 0 ? length(var.target_groups) : 0

  type              = "ingress"
  from_port         = var.target_groups[count.index].port
  to_port           = var.target_groups[count.index].port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nlb[0].id
}

resource "aws_lb" "nlb" {
  count = var.create ? 1 : 0
  name  = local.module_prefix
  tags  = local.tags

  load_balancer_type               = "network"
  internal                         = var.internal
  subnets                          = var.subnet_ids
  enable_cross_zone_load_balancing = var.cross_zone_load_balancing_enabled
  enable_http2                     = var.http2_enabled
  idle_timeout                     = var.idle_timeout
  ip_address_type                  = var.ip_address_type
  enable_deletion_protection       = var.deletion_protection_enabled
}

resource "aws_lb_target_group" "nlb" {
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
    healthy_threshold   = var.target_groups[count.index].health_check.healthy_threshold
    unhealthy_threshold = var.target_groups[count.index].health_check.unhealthy_threshold
    interval            = var.target_groups[count.index].health_check.interval
    protocol            = var.target_groups[count.index].health_check.protocol
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  count = var.create && length(var.target_groups) > 0 ? length(var.target_groups) : 0

  load_balancer_arn = aws_lb.nlb[0].arn
  port              = var.target_groups[count.index].port
  protocol          = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.nlb[count.index].arn
  }
}

resource "aws_route53_record" "nlb" {
  count = var.create && var.dns_zone_id != "" && var.dns_zone_name != "" ? 1 : 0

  zone_id         = var.dns_zone_id
  name            = coalesce(var.domain_name, join(".", [var.name, var.dns_zone_name]))
  type            = "CNAME"
  ttl             = 30
  records         = [aws_lb.nlb[0].dns_name]
  allow_overwrite = true
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "nlb_name" {
  description = "The ARN suffix of the ALB"
  value       = aws_lb.nlb[0].name
}

output "nlb_arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.nlb[0].arn
}

output "nlb_arn_suffix" {
  description = "The ARN suffix of the ALB"
  value       = aws_lb.nlb[0].arn_suffix
}

output "nlb_dns_name" {
  description = "DNS name of ALB"
  value       = aws_lb.nlb[0].dns_name
}

output "nlb_zone_id" {
  description = "The ID of the zone which ALB is provisioned"
  value       = aws_lb.nlb[0].zone_id
}

output "target_group_arns" {
  description = "The target group ARNs"
  value       = aws_lb_target_group.nlb.*.arn
}

output "listener_arns" {
  description = "A list of all the listener ARNs"
  value = compact(
    concat(aws_lb_listener.http.*.arn),
  )
}

output "route53_dns_name" {
  description = "DNS name of Route53"
  value       = length(aws_route53_record.nlb) == 1 ? aws_route53_record.nlb[0].name : ""
}

output "security_group_ids" {
  description = "The security group IDs of the ALB"
  value       = aws_security_group.nlb.*.id
}
