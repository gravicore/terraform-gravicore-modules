module "private_endpoint" {
  depends_on           = [azurerm_key_vault.default]
  count                = var.create ? length(var.private_endpoints) : 0
  source               = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/pep?ref=GDEV-336-release-azure"
  az_region            = var.az_region
  resource_group_name  = var.private_endpoints[count.index].resource_group_name
  target_resource      = one(azurerm_key_vault.default[*].id)
  subnet_id            = var.private_endpoints[count.index].subnet_id
  private_dns_zone_ids = var.private_endpoints[count.index].private_dns_zone_ids
  subresource_name     = var.private_endpoints[count.index].subresource_name
  namespace            = var.namespace
  environment          = var.environment
  stage                = var.stage
  application          = var.application
}

