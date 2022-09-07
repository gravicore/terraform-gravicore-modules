resource "azurerm_key_vault_key" "vm_key" {
  count        = var.create ? 1 : 0
  name         = join(var.delimiter, [local.stage_prefix, "kv", "key", "vm"])
  key_vault_id = concat(azurerm_key_vault.default.*.id, [""])[0]
  tags         = local.tags

  key_type = var.key_type
  key_size = var.key_size
  key_opts = var.key_opts
}

resource "azurerm_key_vault_key" "sa_key" {
  count        = var.create ? 1 : 0
  name         = join(var.delimiter, [local.stage_prefix, "kv", "key", "sa"])
  key_vault_id = concat(azurerm_key_vault.default.*.id, [""])[0]
  tags         = local.tags

  key_type = var.key_type
  key_size = var.key_size
  key_opts = var.key_opts
}
