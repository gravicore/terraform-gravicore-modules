output "profile_name" {
  description = "The name of the CDN FrontDoor Profile."
  value       = one(azurerm_cdn_frontdoor_profile.default[*].name)
}

output "profile_id" {
  description = "The ID of the CDN FrontDoor Profile."
  value       = one(azurerm_cdn_frontdoor_profile.default[*].id)
}

output "endpoints" {
  description = "CDN FrontDoor endpoints outputs."
  value       = { for k, endpoint in azurerm_cdn_frontdoor_endpoint.default : k => endpoint.name }
}

output "origin_groups" {
  description = "CDN FrontDoor origin groups outputs."
  value       = { for k, origin_group in azurerm_cdn_frontdoor_origin_group.default : k => origin_group.name }
}

output "origins" {
  description = "CDN FrontDoor origins outputs."
  value       = { for k, origin in azurerm_cdn_frontdoor_origin.default : k => origin.name }
}

output "custom_domains" {
  description = "CDN FrontDoor custom domains outputs."
  value       = { for k, custom_domain in azurerm_cdn_frontdoor_custom_domain.default : k => custom_domain.name }
}

output "rule_sets" {
  description = "CDN FrontDoor rule sets outputs."
  value       = { for k, rule_set in azurerm_cdn_frontdoor_rule_set.default : k => rule_set.name }
}

output "rules" {
  description = "CDN FrontDoor rules outputs."
  value       = { for k, rule in azurerm_cdn_frontdoor_rule.default : k => rule.name }
}

output "firewall_policies" {
  description = "CDN FrontDoor firewall policies outputs."
  value       = { for k, firewall_policy in azurerm_cdn_frontdoor_firewall_policy.default : k => firewall_policy.name }
}

output "security_policies" {
  description = "CDN FrontDoor security policies outputs."
  value       = { for k, security_policy in azurerm_cdn_frontdoor_security_policy.default : k => security_policy.name }
}

output "validation_token" {
  description = "CDN FrontDoor validation tokens for custom domains."
  value       = { for k, custom_domain in azurerm_cdn_frontdoor_custom_domain.default : k => firewall_policy.validation_token }
}

