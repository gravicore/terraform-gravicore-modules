# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=GDEV-336-release-azure"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# Virtual Machine resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "default" {
  count = local.is_linux ? 1 : 0

  admin_username                  = var.admin_username
  location                        = var.az_region
  name                            = local.module_prefix
  network_interface_ids           = local.network_interface_ids
  resource_group_name             = var.resource_group_name
  size                            = var.size
  admin_password                  = var.admin_password
  allow_extension_operations      = var.allow_extension_operations
  availability_set_id             = var.availability_set_id
  capacity_reservation_group_id   = var.capacity_reservation_group_id
  computer_name                   = var.computer_name
  custom_data                     = var.custom_data
  dedicated_host_group_id         = var.dedicated_host_group_id
  dedicated_host_id               = var.dedicated_host_id
  disable_password_authentication = var.disable_password_authentication
  edge_zone                       = var.edge_zone
  encryption_at_host_enabled      = var.encryption_at_host_enabled
  eviction_policy                 = var.eviction_policy
  extensions_time_budget          = var.extensions_time_budget
  license_type                    = var.license_type
  max_bid_price                   = var.max_bid_price
  patch_assessment_mode           = var.patch_assessment_mode
  patch_mode                      = local.patch_mode
  platform_fault_domain           = var.platform_fault_domain
  priority                        = var.priority
  provision_vm_agent              = var.provision_vm_agent
  proximity_placement_group_id    = var.proximity_placement_group_id
  secure_boot_enabled             = var.secure_boot_enabled
  source_image_id                 = var.source_image_id
  tags                            = merge(local.tags, local.default_vm_tags, var.extra_tags)
  user_data                       = var.user_data
  virtual_machine_scale_set_id    = var.virtual_machine_scale_set_id
  vtpm_enabled                    = var.vtpm_enabled
  zone                            = var.zone

  os_disk {
    caching                          = var.os_disk.caching
    storage_account_type             = var.os_disk.storage_account_type
    disk_encryption_set_id           = var.os_disk.disk_encryption_set_id
    disk_size_gb                     = var.os_disk.disk_size_gb
    name                             = var.os_disk.name == null ? join(var.delimiter, [local.stage_prefix, var.application, module.azure_region.location_short, var.name, "osdisk"]) : var.os_disk.name
    secure_vm_disk_encryption_set_id = var.os_disk.secure_vm_disk_encryption_set_id
    security_encryption_type         = var.os_disk.security_encryption_type
    write_accelerator_enabled        = var.os_disk.write_accelerator_enabled

    dynamic "diff_disk_settings" {
      for_each = var.os_disk.diff_disk_settings == null ? [] : [
        "diff_disk_settings"
      ]

      content {
        option    = var.os_disk.diff_disk_settings.option
        placement = var.os_disk.diff_disk_settings.placement
      }
    }
  }
  dynamic "additional_capabilities" {
    for_each = var.vm_additional_capabilities == null ? [] : [
      "additional_capabilities"
    ]

    content {
      ultra_ssd_enabled = var.vm_additional_capabilities.ultra_ssd_enabled
    }
  }
  dynamic "admin_ssh_key" {
    for_each = { for key in var.admin_ssh_keys : jsonencode(key) => key }

    content {
      public_key = admin_ssh_key.value.public_key
      username   = coalesce(admin_ssh_key.value.username, var.admin_username)
    }
  }
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_storage_account_uri == null ? [] : ["var.boot_diagnostics_storage_account_uri"]

    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }
  dynamic "gallery_application" {
    for_each = { for app in var.gallery_application : jsonencode(app) => app }

    content {
      version_id             = gallery_application.value.version_id
      configuration_blob_uri = gallery_application.value.configuration_blob_uri
      order                  = gallery_application.value.order
      tag                    = gallery_application.value.tag
    }
  }
  dynamic "identity" {
    for_each = var.identity == null ? [] : ["identity"]

    content {
      type         = var.identity.type
      identity_ids = var.identity.identity_ids
    }
  }
  dynamic "plan" {
    for_each = var.plan == null ? [] : ["plan"]

    content {
      name      = var.plan.name
      product   = var.plan.product
      publisher = var.plan.publisher
    }
  }
  dynamic "secret" {
    for_each = toset(var.secrets)

    content {
      key_vault_id = secret.value.key_vault_id

      dynamic "certificate" {
        for_each = secret.value.certificate

        content {
          url = certificate.value.url
        }
      }
    }
  }
  dynamic "source_image_reference" {
    for_each = var.source_image_reference == null ? [] : [
      "source_image_reference"
    ]

    content {
      offer     = var.source_image_reference.offer
      publisher = var.source_image_reference.publisher
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
    }
  }
  dynamic "source_image_reference" {
    for_each = var.os_simple != null && var.source_image_id == null ? [
      "source_image_reference"
    ] : []

    content {
      offer     = var.standard_os[var.os_simple].offer
      publisher = var.standard_os[var.os_simple].publisher
      sku       = var.standard_os[var.os_simple].sku
      version   = var.os_version
    }
  }
  dynamic "termination_notification" {
    for_each = var.termination_notification == null ? [] : [
      "termination_notification"
    ]

    content {
      enabled = var.termination_notification.enabled
      timeout = var.termination_notification.timeout
    }
  }

  lifecycle {
    precondition {
      condition = length([
        for b in [
          var.source_image_id != null, var.source_image_reference != null,
          var.os_simple != null
        ] : b if b
      ]) == 1
      error_message = "Must provide one and only one of `vm_source_image_id`, `vm_source_image_reference` and `vm_os_simple`."
    }
    precondition {
      condition     = var.network_interface_ids != null || var.new_network_interface != null
      error_message = "Either `new_network_interface` or `network_interface_ids` must be provided."
    }
    #Public keys can only be added to authorized_keys file for 'admin_username' due to a known issue in Linux provisioning agent.
    precondition {
      condition     = alltrue([for value in var.admin_ssh_keys : value.username == var.admin_username || value.username == null])
      error_message = "`username` in var.admin_ssh_keys should be the same as `admin_username` or `null`."
    }
  }
}

locals {
  network_interface_ids = var.new_network_interface != null ? [
    azurerm_network_interface.default[0].id
  ] : var.network_interface_ids
}




resource "azurerm_maintenance_assignment_virtual_machine" "maintenance_configurations" {
  for_each                     = toset(var.maintenance_configuration_ids)
  location                     = azurerm_linux_virtual_machine.default[0].location
  maintenance_configuration_id = each.value
  virtual_machine_id           = azurerm_linux_virtual_machine.default[0].id

  lifecycle {
    precondition {
      condition     = var.patch_mode == "AutomaticByPlatform"
      error_message = "The variable patch_mode must be set to AutomaticByPlatform to use maintenance configurations."
    }
  }
}

# Fix typo
moved {
  from = azurerm_maintenance_assignment_virtual_machine.maintenace_configurations
  to   = azurerm_maintenance_assignment_virtual_machine.maintenance_configurations
}

locals {
  backup_resource_group_name = var.backup_policy_id != null ? split("/", var.backup_policy_id)[4] : null
  backup_recovery_vault_name = var.backup_policy_id != null ? split("/", var.backup_policy_id)[8] : null
}



resource "azurerm_backup_protected_vm" "backup" {
  for_each = toset(var.backup_policy_id != null ? ["enabled"] : [])

  resource_group_name = local.backup_resource_group_name
  recovery_vault_name = local.backup_recovery_vault_name
  source_vm_id        = azurerm_linux_virtual_machine.default[0].id
  backup_policy_id    = var.backup_policy_id
}

