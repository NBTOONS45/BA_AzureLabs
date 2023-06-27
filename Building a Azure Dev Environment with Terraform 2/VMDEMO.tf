terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.62.1"
    }
  }
}

provider "azurerm" {
  features {}
  # Configuration options
}

# Create a resource group

resource "azurerm_resource_group" "BA_rg" {
  name     = "BA_resources"
  location = "West Europe"

  tags = {
    environment = "staging"
  }
}

# Create a virtual network within the resource group

resource "azurerm_virtual_network" "BA_vn" {
  name                = "BA_network"
  resource_group_name = azurerm_resource_group.BA_rg.name
  location            = azurerm_resource_group.BA_rg.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "staging"
  }
}

# Create a Subnet

resource "azurerm_subnet" "BA_sn" {
  name                 = "BA_sn"
  resource_group_name  = azurerm_resource_group.BA_rg.name
  virtual_network_name = azurerm_virtual_network.BA_vn.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage"]
}

# Create a Network Security Group

resource "azurerm_network_security_group" "BA_sg" {
  name                = "BA_sg"
  location            = azurerm_resource_group.BA_rg.location
  resource_group_name = azurerm_resource_group.BA_rg.name

  security_rule {
    name                       = "BA_test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Staging"
  }
}

# Associate the NSG with the subnet

resource "azurerm_subnet_network_security_group_association" "BA_nsga" {
  subnet_id                 = azurerm_subnet.BA_sn.id
  network_security_group_id = azurerm_network_security_group.BA_sg.id
}

# Create a Network Interface Card

resource "azurerm_network_interface" "BA_nic" {
  name                = "BA_nic"
  location            = azurerm_resource_group.BA_rg.location
  resource_group_name = azurerm_resource_group.BA_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.BA_sn.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "BA_nic2" {
  name                = "BA_nic2"
  location            = azurerm_resource_group.BA_rg.location
  resource_group_name = azurerm_resource_group.BA_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.BA_sn.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create a storage account

resource "azurerm_storage_account" "BA_sa" {
  name                     = "basa123"
  resource_group_name      = azurerm_resource_group.BA_rg.name
  location                 = azurerm_resource_group.BA_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a storage container

resource "azurerm_storage_container" "BA_sc" {
  name                  = "basc123"
  storage_account_name  = azurerm_storage_account.BA_sa.name
  container_access_type = "private"
}

# Create a blob

resource "azurerm_storage_blob" "BA_blob" {
  name                   = "ba_blob"
  storage_account_name   = azurerm_storage_account.BA_sa.name
  storage_container_name = azurerm_storage_container.BA_sc.name
  type                   = "Block"

}


# Create a Windows Virtual Machine

resource "azurerm_windows_virtual_machine" "BA_wvm" {
  name                = "BA_wvm"
  computer_name       = "wvm"
  resource_group_name = azurerm_resource_group.BA_rg.name
  location            = azurerm_resource_group.BA_rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.BA_nic.id,
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

# Create a Linux Virtual Machine

resource "azurerm_linux_virtual_machine" "balxvm" {
  name                = "balxvm"
  computer_name       = "lxvm"
  resource_group_name = azurerm_resource_group.BA_rg.name
  location            = azurerm_resource_group.BA_rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.BA_nic2.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}
