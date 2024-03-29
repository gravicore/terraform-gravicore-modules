# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=0.46.0"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# Resource Group resource
# ----------------------------------------------------------------------------------------------------------------------


resource "azapi_resource_action" "ssh_public_key_gen" {
  for_each    = var.key_pair
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key[each.key].id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

resource "azapi_resource" "ssh_public_key" {
  for_each  = var.key_pair
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = join(var.delimiter, [local.stage_prefix, var.application, module.azure_region.location_short, each.key, var.name])
  location  = var.az_region
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
}


resource "azurerm_key_vault_secret" "publickey" {
  for_each     = var.key_pair
  name         = each.value.public_key_secret_name
  value        = jsondecode(azapi_resource_action.ssh_public_key_gen[each.key].output).publicKey
  key_vault_id = each.value.key_vault_id
}

resource "azurerm_key_vault_secret" "privatekey" {
  for_each     = var.key_pair
  name         = each.value.private_key_secret_name
  value        = jsondecode(azapi_resource_action.ssh_public_key_gen[each.key].output).privateKey
  key_vault_id = each.value.key_vault_id
}

