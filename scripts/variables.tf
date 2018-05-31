# Azure Provider Variables
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "location" {
    default = "Southeast Asia"
}

# Instance Variables
variable "tags" {
    default = {
        environment = "staging"
        created_by = "terraform"
    }
}

variable "prefix" {
    default = "Drupal"
}

variable "vnet_cidr" {
    default = "192.168.0.0/16"
}

variable "subnet_cidr" {
    default = "192.168.1.0/24"
}


variable "servers" {
    default = 1
    description = "The number of App servers to launch."
}

variable "vm_size" {
    default = "Standard_A0"
    description = "Size of the VM. See https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-sizes/"
}

variable "user_login" {
    default = "testuser"
    description = "Default login for this image"
}

variable "user_password" {
    default = "Password1234!"
    description = "Default password for this image"
}

