# Create Resource Group 
resource "azurerm_resource_group" "example_resource_group" {
  name     = var.rg_name
  location = var.location
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  address_space       = ["10.0.0.0/27"]
  resource_group_name = azurerm_resource_group.example_resource_group.name
}

resource "azurerm_subnet" "tf_subnet_1" {
  name                 = "azure_subnet_terraform"
  address_prefixes     = ["10.0.0.0/28"]
  resource_group_name  = azurerm_resource_group.example_resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

# Create a Network Security Group (NSG) - Allow SSH access
resource "azurerm_network_security_group" "nsg" {
  name                = "my-terraform-nsg"
  location            = azurerm_resource_group.example_resource_group.location
  resource_group_name = azurerm_resource_group.example_resource_group.name

  security_rule {
    name                       = "allow_ssh"
    priority                   = 100
    direction                  = "Inbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    protocol                   = "Tcp"
    access                     = "Allow"
  }
}

# Create Public IP for the VM
resource "azurerm_public_ip" "tf_public_ip" {
  name                = "tf-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.example_resource_group.name
  allocation_method   = "Dynamic"
}

# Create a Network Interface Card (NIC)
resource "azurerm_network_interface" "nic" {
  name                = "my-nic"
  location            = azurerm_resource_group.example_resource_group.location
  resource_group_name = azurerm_resource_group.example_resource_group.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tf_subnet_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tf_public_ip.id
  }

  depends_on = [azurerm_network_security_group.nsg]
}

# Create SSH Key for the VM
resource "azurerm_ssh_public_key" "tf_public_key" {
  name                = "tf_public_key"
  resource_group_name = azurerm_resource_group.example_resource_group.name
  location            = var.location
  public_key          = file(var.ssh_key)
}

# Create Virtual Machine
resource "azurerm_linux_virtual_machine" "vm_terraform" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.example_resource_group.name
  location            = azurerm_resource_group.example_resource_group.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = azurerm_ssh_public_key.tf_public_key.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# Output SSH command
output "ssh_command" {
  value = format("ssh -i ../credentials/id_rsa adminuser@%s", azurerm_linux_virtual_machine.vm_terraform.public_ip_address)
}

# Output Public IP Address
output "public_ip" {
  value = azurerm_linux_virtual_machine.vm_terraform.public_ip_address
}
