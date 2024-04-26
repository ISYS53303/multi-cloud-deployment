# Create a VPC Network for our Virtual Machine
resource "google_compute_network" "vpc_network" {
  name = var.vpc_name
}

# Create a subnet in our VPC
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  region        = var.region
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.0.0.0/28"
}

# Create firewall rule to allow SSH from anywhere
resource "google_compute_firewall" "ssh_rule" {
  name          = var.firewall_rule_name
  network       = google_compute_network.vpc_network.name
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# Create VM Instance
resource "google_compute_instance" "vm_instance" {
  name         = var.vm_name
  machine_type = var.machine_type
  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.name

    access_config {
    }
  }

  metadata = {
    ssh-keys = "adminuser:${file(var.ssh_key)}"
  }
}

# Output details for connecting to the VM
output "vm_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}

output "ssh_command" {
  value = format("ssh -i ../credentials/id_rsa adminuser@%s", google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip)
}
