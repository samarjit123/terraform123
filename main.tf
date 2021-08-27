variable "az_rg_name" {}
variable "az_location" {}
variable "az_env" {}
variable "az_vnet_name" {}
variable "az_subnet_name" {}
variable "az_nic_name" {}
variable "az_vm_name" {}
variable "az_vm_size" {}
variable "az_vm_username" {}
variable "az_vm_password" {}
variable "az_nsg_name" {}
variable "az_publicip_name" {}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "az_rg" {
  name     = "${var.az_rg_name}"
  location = "${var.az_location}"
}

resource "azurerm_virtual_network" "az_vn" {
  name                = "${var.az_vnet_name}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.az_rg.location
  resource_group_name = azurerm_resource_group.az_rg.name
}

resource "azurerm_subnet" "az_subnet" {
  name                 = "${var.az_subnet_name}"
  resource_group_name  = azurerm_resource_group.az_rg.name
  virtual_network_name = azurerm_virtual_network.az_vn.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "az_publicip" {
  name                = "${var.az_publicip_name}"
  resource_group_name = azurerm_resource_group.az_rg.name
  location            = azurerm_resource_group.az_rg.location
  allocation_method   = "Static"
  sku = "Basic"
}

resource "azurerm_network_interface" "az_nic" {
  name                = "${var.az_nic_name}"
  location            = azurerm_resource_group.az_rg.location
  resource_group_name = azurerm_resource_group.az_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.az_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.az_publicip.id
  }
}

resource "azurerm_network_security_group" "az_nsg" {
  name                = "${var.az_nsg_name}"
  location            = azurerm_resource_group.az_rg.location
  resource_group_name = azurerm_resource_group.az_rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "az_nsgsub" {
  subnet_id                 = azurerm_subnet.az_subnet.id
  network_security_group_id = azurerm_network_security_group.az_nsg.id
}

resource "azurerm_windows_virtual_machine" "az_vm" {
  name                = "${var.az_vm_name}"
  resource_group_name = azurerm_resource_group.az_rg.name
  location            = azurerm_resource_group.az_rg.location
  size                = "${var.az_vm_size}"
  admin_username      = "${var.az_vm_username}"
  admin_password      = "${var.az_vm_password}"
  network_interface_ids = [
    azurerm_network_interface.az_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}