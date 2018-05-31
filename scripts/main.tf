provider "azurerm" {
    subscription_id = "${var.subscription_id}"
    client_id = "${var.client_id}"
    client_secret = "${var.client_secret}"
    tenant_id = "${var.tenant_id}"
}
resource "azurerm_resource_group" "DrupalonAzureVM_RG" {
  name 		= "${var.prefix}-${md5("${var.prefix}")}-rg"
  location 	= "${var.location}"
}

resource "azurerm_virtual_network" "DrupalonAzureVM_VNET" {
  name 			= "${var.prefix}-${md5("${var.prefix}")}-vnet"
  address_space 	= ["${var.vnet_cidr}"]
  location 		= "${var.location}"
  resource_group_name   = "${azurerm_resource_group.DrupalonAzureVM_RG.name}"
}

resource "azurerm_subnet" "DrupalonAzureVM_SNET" {
  name 			= "${var.prefix}-${md5("${var.prefix}")}-snet"
  address_prefix 	= "${var.subnet_cidr}"
  virtual_network_name 	= "${azurerm_virtual_network.DrupalonAzureVM_VNET.name}"
  resource_group_name 	= "${azurerm_resource_group.DrupalonAzureVM_RG.name}"
}

resource "azurerm_storage_account" "DrupalonAzureVM_SA" {
  name 			= "${var.prefix}-${md5("${var.prefix}")}-storage"
  resource_group_name 	= "${azurerm_resource_group.DrupalonAzureVM_RG.name}"
  location 		= "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
 
}

resource "azurerm_storage_container" "DrupalonAzureVM_VHDs" {
  name 			= "${var.prefix}-${md5("${var.prefix}")}-vhds"
  resource_group_name 	= "${azurerm_resource_group.DrupalonAzureVM_RG.name}"
  storage_account_name 	= "${azurerm_storage_account.DrupalonAzureVM_SA.name}"
  container_access_type = "private"
}

resource "azurerm_network_security_group" "DrupalonAzureVM_SGs" {
  name 			=  "${var.prefix}-${md5("${var.prefix}")}-SG"
  location 		= "${var.location}"
  resource_group_name 	= "${azurerm_resource_group.DrupalonAzureVM_RG.name}"

  security_rule {
	name 			= "Allowhttps"
	priority 		= 100
	direction 		= "Inbound"
	access 		        = "Allow"
	protocol 		= "Tcp"
	source_port_range       = "*"
    destination_port_range     	= "443"
    source_address_prefix      	= "*"
    destination_address_prefix 	= "*"
  }

  security_rule {
	name 			= "AllowHTTP"
	priority		= 200
	direction		= "Inbound"
	access 			= "Allow"
	protocol 		= "Tcp"
	source_port_range       = "*"
    destination_port_range     	= "80"
    source_address_prefix      	= "Internet"
    destination_address_prefix 	= "*"
  }
  
}

resource "azurerm_public_ip" "DrupalonAzureVM_PIP" {
  name 				= "${var.prefix}-${md5("${var.prefix}")}-pip"
  location 			= "${var.location}"
  resource_group_name 		= "${azurerm_resource_group.DrupalonAzureVM_RG.name}"
  public_ip_address_allocation 	= "dynamic"

}

resource "azurerm_network_interface" "DrupalonAzureVM_NIC" {
  name 		      = "${var.prefix}-${md5("${var.prefix}")}-NIC"
  location 	      = "${var.location}"
  resource_group_name = "${azurerm_resource_group.DrupalonAzureVM_RG.name}"
  network_security_group_id = "${azurerm_network_security_group.DrupalonAzureVM_SGs.id}"

  ip_configuration {
    name 			= "${var.prefix}-configuration""
    subnet_id 			= "${azurerm_subnet.DrupalonAzureVM_SNET.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id	= "${azurerm_public_ip.DrupalonAzureVM_PIP.id}"
  }
}


resource "azurerm_virtual_machine" "DrupalonAzureVM_web" {
  name                  = "${var.prefix}-${md5("${var.prefix}")}-vm"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.DrupalonAzureVM_RG.name}"
  network_interface_ids = ["${azurerm_network_interface.DrupalonAzureVM_NIC.id}"]
  vm_size               = "${var.vm_size}"

#This will delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "14.04.2-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "osdisk-1"
    vhd_uri       = "${azurerm_storage_account."DrupalonAzureVM_SA.primary_blob_endpoint}${azurerm_storage_container."DrupalonAzureVM_VHDs.name}/osdisk-1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.prefix}-vm"
    admin_username = "${var.user_login}"
    admin_password =  "${var.user_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}

resource "azurerm_virtual_machine_extension" "DrupalonAzureVM_CustomScriptExtension" {
  name                 = "${var.prefix}-CustomScriptExtension"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.DrupalonAzureVM_RG.name}"
  depends_on           = ["azurerm_virtual_machine.DrupalonAzureVM_web"]
  virtual_machine_name = "${var.prefix}-${md5("${var.prefix}")}-vm"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"  
  settings = <<SETTINGS
    {
 "fileUris":[ "https://raw.githubusercontent.com/Jagadt/MyARM/master/install_drupal.sh"],
        "commandToExecute": "sh install_drupal.sh"
    }
SETTINGS

}
