# Windows VM with option for Load Balancer
locals {
  av_zones                  = ["1", "2", "3"]
  vm_datadiskdisk_count_map = { for idx, k in var.virtual_machine_names : k => idx }
  datadisk_sizes            = { for k in local.datadisk_lun_map : k.datadisk_name => k.datadisk_size }
  storage_account_types     = { for k in local.datadisk_lun_map : k.datadisk_name => k.storage_account_type }
  luns                      = { for idx, k in local.datadisk_lun_map : k.datadisk_name => idx }
  zones                     = { for k in local.datadisk_lun_map : k.datadisk_name => k.zone }
  vm_ids                    = { for k in local.datadisk_lun_map : k.datadisk_name => k.vm_id }
  datadisk_lun_map = flatten([
    for vm_name, idx in local.vm_datadiskdisk_count_map : [
      for i in var.data_disks : {
        datadisk_name        = format("datadisk_%s_disk%s", vm_name, i.name)
        zone                 = element(local.av_zones, (idx % 3) + (var.vm_availability_zone - 1))
        vm_id                = idx
        datadisk_size        = i.disk_size_gb
        storage_account_type = i.storage_account_type
      }
    ]
  ])
}
#---------------------------------------
# data  varaibles
#---------------------------------------
data "azurerm_subnet" "vnet-subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.vnet_resource_group_name
}

data "azurerm_storage_account" "storeacc" {
  count               = var.storage_account_name != null ? 1 : 0
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault" "kevvaultshared" {
  name                = var.keyvault_name
  resource_group_name = var.keyvault_resource_group_name
}

#---------------------------------------
# Network interface creation
#---------------------------------------
resource "azurerm_network_interface" "nic" {
  for_each            = { for idx, server in var.virtual_machine_names : idx => server }
  name                = "${each.value}_Network_Interface"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "${each.value}_Network_Interface_Ip_Config"
    subnet_id                     = data.azurerm_subnet.vnet-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

#---------------------------------------
# Virttual machine
#---------------------------------------

resource "random_password" "passwd" {
  count       = (var.admin_password == null ? 1 : 0)
  length      = var.random_password_length
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false
}

resource "azurerm_windows_virtual_machine" "win_vm" {
  for_each                   = { for idx, server in var.virtual_machine_names : idx => server }
  name                       = each.value
  resource_group_name        = var.resource_group_name
  location                   = var.location
  size                       = var.virtual_machine_size
  admin_username             = var.admin_username
  admin_password             = var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password
  network_interface_ids      = [azurerm_network_interface.nic[each.key].id, ]
  source_image_id            = var.source_image_id != null ? var.source_image_id : null
  provision_vm_agent         = true
  allow_extension_operations = true
  dedicated_host_id          = var.dedicated_host_id
  custom_data                = var.custom_data != null ? var.custom_data : null
  enable_automatic_updates   = var.enable_automatic_updates
  license_type               = var.license_type
  #vailability_set_id          = var.enable_vm_availability_set == true ? element(concat(azurerm_availability_set.aset.*.id, [""]), 0) : null
  encryption_at_host_enabled = var.enable_encryption_at_host
  #proximity_placement_group_id = var.enable_proximity_placement_group ? azurerm_proximity_placement_group.appgrp.0.id : null
  patch_mode = var.patch_mode
  zone       = element(local.av_zones, (each.key % 3) + (var.vm_availability_zone - 1))
  timezone   = var.vm_time_zone
  tags       = var.tags


  os_disk {
    storage_account_type      = var.os_disk_storage_account_type
    caching                   = var.os_disk_caching
    disk_encryption_set_id    = var.disk_encryption_set_id
    disk_size_gb              = var.disk_size_gb
    write_accelerator_enabled = var.enable_os_disk_write_accelerator
    name                      = var.os_disk_name
  }

  source_image_reference {
    publisher = var.custom_image != null ? var.custom_image["publisher"] : var.windows_distribution_list[lower(var.windows_distribution_name)]["publisher"]
    offer     = var.custom_image != null ? var.custom_image["offer"] : var.windows_distribution_list[lower(var.windows_distribution_name)]["offer"]
    sku       = var.custom_image != null ? var.custom_image["sku"] : var.windows_distribution_list[lower(var.windows_distribution_name)]["sku"]
    version   = var.custom_image != null ? var.custom_image["version"] : var.windows_distribution_list[lower(var.windows_distribution_name)]["version"]
  }

  additional_capabilities {
    ultra_ssd_enabled = var.enable_ultra_ssd_data_disk_storage_support
  }

  dynamic "identity" {
    for_each = var.managed_identity_type != null ? [1] : []
    content {
      type         = var.managed_identity_type
      identity_ids = var.managed_identity_type == "UserAssigned" || var.managed_identity_type == "SystemAssigned, UserAssigned" ? var.managed_identity_ids : null
    }
  }

  dynamic "winrm_listener" {
    for_each = var.winrm_protocol != null ? [1] : []
    content {
      protocol        = var.winrm_protocol
      certificate_url = var.winrm_protocol == "Https" ? var.key_vault_certificate_secret_url : null
    }
  }

  dynamic "additional_unattend_content" {
    for_each = var.additional_unattend_content != null ? [1] : []
    content {
      content = var.additional_unattend_content
      setting = var.additional_unattend_content_setting
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = var.storage_account_name != null ? data.azurerm_storage_account.storeacc.0.primary_blob_endpoint : var.storage_account_uri
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
      patch_mode,
    ]
  }
}

#---------------------------------------
# Virtual machine data disks
#---------------------------------------
resource "azurerm_managed_disk" "managed_disk" {
  for_each             = toset([for j in local.datadisk_lun_map : j.datadisk_name])
  name                 = each.key
  resource_group_name  = var.resource_group_name
  location             = var.location
  storage_account_type = lookup(local.storage_account_types, each.key)
  create_option        = "Empty"
  disk_size_gb         = lookup(local.datadisk_sizes, each.key)
  zone                 = lookup(local.zones, each.key)
  tags                 = var.tags
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "managed_disk_attach" {
  for_each           = toset([for j in local.datadisk_lun_map : j.datadisk_name])
  managed_disk_id    = azurerm_managed_disk.managed_disk[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.win_vm[lookup(local.vm_ids, each.key)].id
  lun                = lookup(local.luns, each.key) + 1
  caching            = "ReadWrite"
}

#---------------------------------------
# Load balancer creation
#---------------------------------------
resource "azurerm_lb" "tf_lb" {
  count               = length(var.loadbalancer_endpoints) >= 1 ? 1 : 0
  name                = var.loadbalancer_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                          = "${var.loadbalancer_name}-privateip"
    subnet_id                     = data.azurerm_subnet.vnet-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_lb_backend_address_pool" "tf_lb_ad_pool" {
  count           = length(var.loadbalancer_endpoints) >= 1 ? 1 : 0
  loadbalancer_id = azurerm_lb.tf_lb[0].id // azurerm_lb.tf_lb[count.index].id
  name            = "${var.loadbalancer_name}-BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "tf_lb_ad_pool_association" {
  count                   = length(var.loadbalancer_endpoints) >= 1 ? length(var.virtual_machine_names) : 0
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "${var.virtual_machine_names[count.index]}_Network_Interface_Ip_Config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.tf_lb_ad_pool[0].id
}

resource "azurerm_lb_probe" "tf_lb_probe" {
  count           = length(var.loadbalancer_endpoints) >= 1 ? length(var.loadbalancer_endpoints) : 0
  loadbalancer_id = azurerm_lb.tf_lb[0].id
  name            = "port-${lookup(var.loadbalancer_endpoints[count.index], "name")}-probe"
  #resource_group_name  = var.resource_group_name
  port                = lookup(var.loadbalancer_endpoints[count.index].probe, "probe_port")
  protocol            = lookup(var.loadbalancer_endpoints[count.index].probe, "protocol")
  request_path        = lookup(var.loadbalancer_endpoints[count.index].probe, "request_path")
  interval_in_seconds = lookup(var.loadbalancer_endpoints[count.index].probe, "interavl_in_seconds")
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "tf_lb_rule" {
  count           = length(var.loadbalancer_endpoints) >= 1 ? length(var.loadbalancer_endpoints) : 0
  loadbalancer_id = azurerm_lb.tf_lb[0].id
  name            = "lb-${lookup(var.loadbalancer_endpoints[count.index], "name")}-rule"
  #resource_group_name           = var.resource_group_name
  protocol                       = lookup(var.loadbalancer_endpoints[count.index].rule, "protocol")
  frontend_port                  = lookup(var.loadbalancer_endpoints[count.index].rule, "frontend_port")
  backend_port                   = lookup(var.loadbalancer_endpoints[count.index].rule, "backend_port")
  frontend_ip_configuration_name = "${var.loadbalancer_name}-privateip"                    //"publicIPAddress"
  probe_id                       = element(azurerm_lb_probe.tf_lb_probe.*.id, count.index) //azurerm_lb_probe.tf_lb_probe[count.index].id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.tf_lb_ad_pool[0].id]
  load_distribution              = var.load_distribution
}

#---------------------------------------
# key valut creation
#---------------------------------------
resource "azurerm_key_vault_secret" "vmpassword" {
  for_each     = { for idx, server in var.virtual_machine_names : idx => server }
  name         = "${each.value}-vmpassword"
  value        = var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password
  key_vault_id = data.azurerm_key_vault.kevvaultshared.id //"/subscriptions/25602c15-362d-4788-bf93-d15cd933ff6a/resourceGroups/AZRG-USE2-TX-SHD-DEV/providers/Microsoft.KeyVault/vaults/azuse2shddevakv01"
}
