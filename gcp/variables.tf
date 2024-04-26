variable "ssh_key" {
  default = "../credentials/id_rsa.pub"
}

variable "gcp_key" {
  default = "./gcp-key.json"
}

variable "vpc_name" {
  default = "my-vpc-network"
}

variable "subnet_name" {
  default = "my-subnet"
}

variable "firewall_rule_name" {
  default = "allow-ssh-rule"
}

variable "region" {
  default = "us-central1"
}

variable "vm_name" {
  default = "my-vm-instance"
}

variable "machine_type" {
  default = "f1-micro"
}

variable "image" {
  default = "debian-cloud/debian-11"
}
