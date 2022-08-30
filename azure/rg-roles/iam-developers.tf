resource "azurerm_role_definition" "developer" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [var.namespace, "developer", ])
  scope = data.azurerm_subscription.current.id

  permissions {
    actions     = var.developer_policy_allow
    not_actions = var.developer_policy_deny
  }
}
