
resource "azurerm_role_assignment" "rbac_user_login" {
  for_each             = toset(var.aad_ssh_login_enabled ? var.aad_ssh_login_user_objects_ids : [])
  principal_id         = each.value
  scope                = azurerm_linux_virtual_machine.default[0].id
  role_definition_name = "Virtual Machine User Login"
}

resource "azurerm_role_assignment" "rbac_admin_login" {
  for_each             = toset(var.aad_ssh_login_enabled ? var.aad_ssh_login_admin_objects_ids : [])
  principal_id         = each.value
  scope                = azurerm_linux_virtual_machine.default[0].id
  role_definition_name = "Virtual Machine Administrator Login"
}


resource "azurerm_virtual_machine_extension" "extensions" {
  # The `sensitive` inside `nonsensitive` is a workaround for https://github.com/terraform-linters/tflint-ruleset-azurerm/issues/229
  for_each = nonsensitive({ for e in var.extensions : e.name => e })

  name                        = each.key
  publisher                   = each.value.publisher
  type                        = each.value.type
  type_handler_version        = each.value.type_handler_version
  virtual_machine_id          = local.virtual_machine.id
  auto_upgrade_minor_version  = each.value.auto_upgrade_minor_version
  automatic_upgrade_enabled   = each.value.automatic_upgrade_enabled
  failure_suppression_enabled = each.value.failure_suppression_enabled
  protected_settings          = each.value.protected_settings
  settings                    = each.value.settings
  tags                        = merge(local.tags, local.default_vm_tags, var.extra_tags, var.extensions_extra_tags)

  dynamic "protected_settings_from_key_vault" {
    for_each = each.value.protected_settings_from_key_vault == null ? [] : [
      "protected_settings_from_key_vault"
    ]

    content {
      secret_url      = each.value.protected_settings_from_key_vault.secret_url
      source_vault_id = each.value.protected_settings_from_key_vault.source_vault_id
    }
  }

  depends_on = [azurerm_virtual_machine_data_disk_attachment.default]
}

resource "azurerm_virtual_machine_extension" "aad_ssh_login" {
  for_each = toset(var.aad_ssh_login_enabled ? ["enabled"] : [])

  name                       = "${azurerm_linux_virtual_machine.default[0].name}-AADSSHLoginForLinux"
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = var.aad_ssh_login_extension_version
  virtual_machine_id         = azurerm_linux_virtual_machine.default[0].id
  auto_upgrade_minor_version = true

  tags = merge(local.tags, local.default_vm_tags, var.extra_tags, var.extensions_extra_tags)
}


resource "azurerm_virtual_machine_extension" "log_extension" {
  for_each = toset(var.log_analytics_agent_enabled ? ["enabled"] : [])

  name = "${azurerm_linux_virtual_machine.default[0].name}-logextension"

  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OMSAgentforLinux"
  type_handler_version       = var.log_analytics_agent_version
  auto_upgrade_minor_version = true

  virtual_machine_id = azurerm_linux_virtual_machine.default[0].id

  settings = <<SETTINGS
  {
    "workspaceId": "${var.log_analytics_workspace_guid}"
  }
SETTINGS

  protected_settings = <<SETTINGS
  {
    "workspaceKey": "${var.log_analytics_workspace_key}"
  }
SETTINGS

  tags = merge(local.tags, local.default_vm_tags, var.extra_tags, var.extensions_extra_tags)

  lifecycle {
    precondition {
      condition     = var.log_analytics_workspace_guid != null && var.log_analytics_workspace_key != null
      error_message = "Variables log_analytics_workspace_guid and log_analytics_workspace_key must be set when Log Analytics agent is enabled."
    }
  }
}
