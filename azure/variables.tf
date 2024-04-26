variable "location" {
  default = "East US"
}

variable "rg_name" {
  default = "example_rg_terraform"
}

variable "vnet_name" {
  default = "azure_vnet_terraform"
}

variable "ssh_key" {
  default = "../credentials/id_rsa.pub"
}
