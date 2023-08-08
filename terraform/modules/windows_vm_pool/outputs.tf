output"vm_ids" {
    description = "Virtual machine ids created."
    value = values(azurerm_windows_virtual_machine.win_vm)[*].id
}
output"network_interface_ids" {
    description = "ids of the vm nics provisoned."
    value = values(azurerm_network_interface.nic)[*].id
}

output"data_disk_ids" {
    description = "ids of the data disk provisoned."
    value = values(azurerm_managed_disk.managed_disk)[*].id
}

output "vm_passsword" {
  value     = "${random_password.passwd.*.result}"
  sensitive = true
}

output"vm_ids_zone" {
    description = "Virtual machine ids created."
    value = values(azurerm_windows_virtual_machine.win_vm)[*].zone
}


output "loadbalancer_id" {
  value     = "${azurerm_lb.tf_lb.*.id}"
}