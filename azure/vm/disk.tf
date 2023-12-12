resource "azurerm_managed_disk" "disk" {
  for_each = { for d in var.data_disks : d.attach_setting.lun => d }

  create_option                    = each.value.create_option
  location                         = var.az_region
  name                             = join(var.delimiter, [local.stage_prefix, var.application, module.azure_region.location_short, each.value.name, "datadisk"])
  resource_group_name              = var.resource_group_name
  storage_account_type             = each.value.storage_account_type
  disk_access_id                   = each.value.disk_access_id
  disk_encryption_set_id           = each.value.disk_encryption_set_id
  disk_iops_read_only              = each.value.disk_iops_read_only
  disk_iops_read_write             = each.value.disk_iops_read_write
  disk_mbps_read_only              = each.value.disk_mbps_read_only
  disk_mbps_read_write             = each.value.disk_mbps_read_write
  disk_size_gb                     = each.value.disk_size_gb
  edge_zone                        = var.edge_zone
  gallery_image_reference_id       = each.value.gallery_image_reference_id
  hyper_v_generation               = each.value.hyper_v_generation
  image_reference_id               = each.value.image_reference_id
  logical_sector_size              = each.value.logical_sector_size
  max_shares                       = each.value.max_shares
  network_access_policy            = each.value.network_access_policy
  on_demand_bursting_enabled       = each.value.on_demand_bursting_enabled
  os_type                          = title(var.image_os)
  public_network_access_enabled    = each.value.public_network_access_enabled
  secure_vm_disk_encryption_set_id = each.value.secure_vm_disk_encryption_set_id
  security_type                    = each.value.security_type
  source_resource_id               = each.value.source_resource_id
  source_uri                       = each.value.source_uri
  storage_account_id               = each.value.storage_account_id
  tags                             = merge(local.tags, local.default_vm_tags, var.extra_tags)

  tier                   = each.value.tier
  trusted_launch_enabled = each.value.trusted_launch_enabled
  upload_size_bytes      = each.value.upload_size_bytes
  zone                   = var.zone

  dynamic "encryption_settings" {
    for_each = each.value.encryption_settings == null ? [] : [
      "encryption_settings"
    ]

    content {
      dynamic "disk_encryption_key" {
        for_each = each.value.encryption_settings.disk_encryption_key == null ? [] : [
          "disk_encryption_key"
        ]

        content {
          secret_url      = each.value.encryption_settings.disk_encryption_key.secret_url
          source_vault_id = each.value.encryption_settings.disk_encryption_key.source_vault_id
        }
      }
      dynamic "key_encryption_key" {
        for_each = each.value.encryption_settings.key_encryption_key == null ? [] : [
          "key_encryption_key"
        ]

        content {
          key_url         = each.value.encryption_settings.key_encryption_key.key_url
          source_vault_id = each.value.encryption_settings.key_encryption_key.source_vault_id
        }
      }
    }
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "default" {
  for_each = {
    for d in var.data_disks : d.attach_setting.lun => d.attach_setting
  }

  caching                   = each.value.caching
  lun                       = each.value.lun
  managed_disk_id           = azurerm_managed_disk.disk[each.key].id
  virtual_machine_id        = local.virtual_machine.id
  create_option             = each.value.create_option
  write_accelerator_enabled = each.value.write_accelerator_enabled
}

