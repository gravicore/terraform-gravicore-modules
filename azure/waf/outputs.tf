output "waf_id" {
  value = concat(azurerm_web_application_firewall_policy.default[*].id, [""])[0]
}

