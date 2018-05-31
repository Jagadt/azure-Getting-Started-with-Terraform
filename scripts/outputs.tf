output "vm_ids" {
	value = ["${azurerm_virtual_machine.DrupalonAzureVM_vm.*.id}"]
}

output "vm_pips" {
	value = ["${azurerm_public_ip.DrupalonAzureVM_pip.*.ip_address}"]
}
