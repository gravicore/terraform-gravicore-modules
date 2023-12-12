locals {
  virtual_machine = local.is_windows ? {
    id                            = try(azurerm_windows_virtual_machine.vm_windows[0].id, null)
    name                          = try(azurerm_windows_virtual_machine.vm_windows[0].name, null)
    admin_username                = try(azurerm_windows_virtual_machine.vm_windows[0].admin_username, null)
    network_interface_ids         = try(azurerm_windows_virtual_machine.vm_windows[0].network_interface_ids, null)
    availability_set_id           = try(azurerm_windows_virtual_machine.vm_windows[0].availability_set_id, null)
    capacity_reservation_group_id = try(azurerm_windows_virtual_machine.vm_windows[0].capacity_reservation_group_id, null)
    computer_name                 = try(azurerm_windows_virtual_machine.vm_windows[0].computer_name, null)
    dedicated_host_id             = try(azurerm_windows_virtual_machine.vm_windows[0].dedicated_host_id, null)
    dedicated_host_group_id       = try(azurerm_windows_virtual_machine.vm_windows[0].dedicated_host_group_id, null)
    patch_mode                    = try(azurerm_windows_virtual_machine.vm_windows[0].patch_mode, null)
    proximity_placement_group_id  = try(azurerm_windows_virtual_machine.vm_windows[0].proximity_placement_group_id, null)
    source_image_id               = try(azurerm_windows_virtual_machine.vm_windows[0].source_image_id, null)
    virtual_machine_scale_set_id  = try(azurerm_windows_virtual_machine.vm_windows[0].virtual_machine_scale_set_id, null)
    timezone                      = try(azurerm_windows_virtual_machine.vm_windows[0].timezone, null)
    zone                          = try(azurerm_windows_virtual_machine.vm_windows[0].zone, null)
    identity                      = try(azurerm_windows_virtual_machine.vm_windows[0].identity, null)
    source_image_reference        = try(azurerm_windows_virtual_machine.vm_windows[0].source_image_reference, null)
    } : {
    id                            = try(azurerm_linux_virtual_machine.default[0].id, null)
    name                          = try(azurerm_linux_virtual_machine.default[0].name, null)
    admin_username                = try(azurerm_linux_virtual_machine.default[0].admin_username, null)
    network_interface_ids         = try(azurerm_linux_virtual_machine.default[0].network_interface_ids, null)
    availability_set_id           = try(azurerm_linux_virtual_machine.default[0].availability_set_id, null)
    capacity_reservation_group_id = try(azurerm_linux_virtual_machine.default[0].capacity_reservation_group_id, null)
    computer_name                 = try(azurerm_linux_virtual_machine.default[0].computer_name, null)
    dedicated_host_id             = try(azurerm_linux_virtual_machine.default[0].dedicated_host_id, null)
    dedicated_host_group_id       = try(azurerm_linux_virtual_machine.default[0].dedicated_host_group_id, null)
    patch_mode                    = try(azurerm_linux_virtual_machine.default[0].patch_mode, null)
    proximity_placement_group_id  = try(azurerm_linux_virtual_machine.default[0].proximity_placement_group_id, null)
    source_image_id               = try(azurerm_linux_virtual_machine.default[0].source_image_id, null)
    virtual_machine_scale_set_id  = try(azurerm_linux_virtual_machine.default[0].virtual_machine_scale_set_id, null)
    timezone                      = null
    zone                          = try(azurerm_linux_virtual_machine.default[0].zone, null)
    identity                      = try(azurerm_linux_virtual_machine.default[0].identity, null)
    source_image_reference        = try(azurerm_linux_virtual_machine.default[0].source_image_reference, null)
  }
}

locals {
  is_linux                                   = var.image_os == "linux"
  is_windows                                 = var.image_os == "windows"
  network_interface_ip_configuration_indexes = var.new_network_interface == null ? [] : toset(range(length(var.new_network_interface.ip_configurations)))
  patch_mode                                 = coalesce(var.patch_mode, local.is_linux ? "ImageDefault" : "AutomaticByOS")
  ip_configuration_name                      = join("-", [local.module_prefix, "nic", "ipconfig"])
  dcr_name                                   = coalesce(var.custom_dcr_name, format("%s-dcra", azurerm_linux_virtual_machine.default[0].name))

}

locals {
  default_vm_tags = var.default_tags_enabled ? {
    os_family       = "linux"
    os_distribution = lookup(var.source_image_reference, "offer", "undefined")
    os_version      = lookup(var.source_image_reference, "sku", "undefined")
  } : {}
}

