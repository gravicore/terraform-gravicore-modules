# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  type        = string
  description = "VPC ID to associate with NLB"
}
variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs to associate with NLB"
}

variable "internal" {
  type        = bool
  default     = false
  description = "A bool flag to determine whether the NLB should be internal"
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
variable "cross_zone_load_balancing_enabled" {
  type        = bool
  default     = true
  description = "A bool flag to enable/disable cross zone load balancing"
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
  default     = true
  description = "A bool flag to enable/disable deletion protection for NLB"
}
variable "target_groups" {
  type        = map(any)
  default     = null
  description = <<EOF
  Map of NLB target group configurations
target_groups = {
  port = {                           = number,    (Required) Port on which targets receive traffic, unless overridden when registering a specific target. Required when target_type is instance, ip or alb. Does not apply when target_type is lambda.                           
    target_type                      = string,    (Required) Type of target that you must specify when registering targets with this target group. See doc for supported values. The default is instance. Note that you can't specify targets for a target group using both instance IDs and IP addresses. If the target type is ip, specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). You can't specify publicly routable IP addresses. Network Load Balancers do not support the lambda target type. Application Load Balancers do not support the alb target type.
    protocol                         = string,    (Required) Protocol to use for routing traffic to the targets. Should be one of TCP, TCP_UDP, TLS, or UDP. Required when target_type is instance, ip or alb. Does not apply when target_type is lambda.
    deregistration_delay             = number,    (Optional) Amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. The default value is 300 seconds.
    preserve_client_ip               = bool,      (Optional) Indicates whether client IP preservation is enabled. The value is true or false. The default is false.
    health_check_enabled             = bool,      (Optional) Whether health checks are enabled. Defaults to true.
    health_check_protocol            = string,    (Optional) Protocol to use to connect with the target. Defaults to HTTP. Not applicable when target_type is lambda.
    health_check_port                = string,    (Optional) Port to use to connect with the target. Valid values are either ports 1-65535, or traffic-port. Defaults to traffic-port.
    health_check_interval            = number,    (Optional) Approximate amount of time, in seconds, between health checks of an individual target. Minimum value 5 seconds, Maximum value 300 seconds. For lambda target groups, it needs to be greater as the timeout of the underlying lambda. Default 30 seconds.
    health_check_healthy_threshold   = number,    (Optional) Number of consecutive health checks successes required before considering an unhealthy target healthy. Defaults to 3.
    health_check_unhealthy_threshold = number,    (Optional) Number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy_threshold. Defaults to 3.
    listener_protocol                = string,    (Optional) Protocol to use to connect with the listener. Defaults to HTTP. Not applicable when target_type is lambda.
  }
}
EOF
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_lb" "nlb" {
  count = var.create ? 1 : 0
  name  = local.module_prefix
  tags  = local.tags

  load_balancer_type               = "network"
  internal                         = var.internal
  subnets                          = var.subnet_ids
  enable_cross_zone_load_balancing = var.cross_zone_load_balancing_enabled
  idle_timeout                     = var.idle_timeout
  ip_address_type                  = var.ip_address_type
  enable_deletion_protection       = var.deletion_protection_enabled
}

resource "aws_lb_target_group" "nlb" {
  for_each = var.create && var.target_groups != null ? var.target_groups : {}
  name     = lower(join("-", [local.module_prefix, lookup(each.value, "protocol", "TCP"), each.key]))
  tags     = local.tags

  vpc_id               = var.vpc_id
  port                 = each.key
  protocol             = lookup(each.value, "protocol", "TCP")
  target_type          = lookup(each.value, "target_type", "instance")
  deregistration_delay = lookup(each.value, "deregistration_delay", 15)
  preserve_client_ip   = lookup(each.value, "preserve_client_ip", false)
  health_check {
    enabled             = lookup(each.value, "health_check_enabled", true)
    healthy_threshold   = lookup(each.value, "health_check_healthy_threshold", 2)
    unhealthy_threshold = lookup(each.value, "health_check_unhealthy_threshold", 2)
    interval            = lookup(each.value, "health_check_interval", 10)
    protocol            = lookup(each.value, "health_check_protocol", "TCP")
    port                = lookup(each.value, "health_check_port", "traffic-port")
  }

  dynamic "stickiness" {
    for_each = lookup(each.value, "enabled", null) == null ? [] : [each.value]
    content {
      type    = lookup(stickiness.value, "type", "source_ip")
      enabled = lookup(stickiness.value, "enabled", false)
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "nlb" {
  for_each = var.create ? aws_lb_target_group.nlb : {}

  load_balancer_arn = aws_lb.nlb[0].arn
  port              = each.value["port"]
  protocol          = each.value["protocol"]
  default_action {
    type             = "forward"
    target_group_arn = each.value["arn"]
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
  description = "The ARN suffix of the NLB"
  value       = concat(aws_lb.nlb.*.name, [""])[0]
}

output "nlb_arn" {
  description = "The ARN of the NLB"
  value       = concat(aws_lb.nlb.*.arn, [""])[0]
}

output "nlb_arn_suffix" {
  description = "The ARN suffix of the NLB"
  value       = concat(aws_lb.nlb.*.arn_suffix, [""])[0]
}

output "nlb_dns_name" {
  description = "DNS name of NLB"
  value       = concat(aws_lb.nlb.*.dns_name, [""])[0]
}

output "nlb_zone_id" {
  description = "The ID of the zone which NLB is provisioned"
  value       = concat(aws_lb.nlb.*.zone_id, [""])[0]
}

output "target_group_arns" {
  description = "The target group ARNs"
  value = [
    for v in aws_lb_target_group.nlb : v.arn
  ]
}

output "target_group_ports" {
  description = "The target group ports"
  value = [
    for v in aws_lb_target_group.nlb : v.port
  ]
}

output "listener_arns" {
  description = "A list of all the listener ARNs"
  value = [
    for v in aws_lb_listener.nlb : v.arn
  ]
}

output "route53_dns_name" {
  description = "DNS name of Route53"
  value       = length(aws_route53_record.nlb) == 1 ? aws_route53_record.nlb[0].name : ""
}
