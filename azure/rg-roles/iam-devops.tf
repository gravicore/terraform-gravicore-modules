resource "azurerm_role_definition" "devops" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [var.namespace, "devops", "access"])
  scope = azurerm_subscription.current.id

  permissions {
    actions     = var.devop_policy_allow
    not_actions = var.devop_policy_deny
  }
}
