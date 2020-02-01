provider "google" {
  credentials = var.credentials_file_path

  region = var.region
  zone   = var.region_zone
}

resource "google_project" "test-terraform-project" {
  name       = "test-terraform"
  project_id = var.project-id
}

resource "google_compute_network" "vpc_network" {
  project                 = google_project.test-terraform-project.project_id
  name                    = "test-terraform-network"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "vpc_firewall_ssh" {
  name    = "allow-ssh"
  project = google_compute_network.vpc_network.project

  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "vpc_firewall_web" {
  name    = "allow-http-and-https"
  project = google_compute_network.vpc_network.project

  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}

data "google_compute_address" "vpc_address" {
  name    = "vm-intance-external-ip"
  project = google_project.test-terraform-project.project_id
}

resource "google_compute_instance" "vm_instance" {
  name    = "test-terraform-instance"
  project = google_project.test-terraform-project.project_id

  machine_type = "n1-standard-1"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
      nat_ip = data.google_compute_address.vpc_address.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh-user}:${file(var.ssh-key-path)}"
  }
}

output "ip" {
  value = data.google_compute_address.vpc_address.address
}