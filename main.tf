terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0" # or ~> 5.0 if you're staying on 5
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "tls_private_key" "user_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "default" {
  name    = "allow-ssh-tester"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "debian_vm" {
  name         = var.vm_name
  machine_type = "c3-standard-4"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12-bookworm-v20250311"
      size  = 40
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    ssh-keys     = "${var.vm_username}:${tls_private_key.user_ssh_key.public_key_openssh}"
    API_KEY      = var.api_key
    PROFILE_NAME = var.profile_name
    GIT_REPO_URL = var.git_repo_url
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    exec > /var/log/startup-script.log 2>&1
    set -ex

    USERNAME="${var.vm_username}"

    # Create the user if it doesn't exist
    id -u $USERNAME &>/dev/null || useradd -m -s /bin/bash $USERNAME

    # Fetch metadata variables
    api_key=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/attributes/API_KEY" -H "Metadata-Flavor: Google")
    profile_name=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/attributes/PROFILE_NAME" -H "Metadata-Flavor: Google")
    repo_url=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/attributes/GIT_REPO_URL" -H "Metadata-Flavor: Google")

    # Set environment vars in bashrc
    echo 'export API_KEY="'$api_key'"' >> /home/$USERNAME/.bashrc
    echo 'export PROFILE_NAME="'$profile_name'"' >> /home/$USERNAME/.bashrc
    chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc

    # Install Git
    apt update
    apt install git -y

    sudo -u $USERNAME -H env repo_url="$repo_url" bash -c "
    cd /home/$USERNAME
    git clone "$repo_url"
    cd $(basename "$repo_url" .git)
    rm -Rf .git*
    source install.sh
    "
  EOT
}

resource "local_file" "user_private_key" {
  filename        = "${path.module}/ssh_key"
  content         = tls_private_key.user_ssh_key.private_key_pem
  file_permission = "0600"
}

output "ssh_connection" {
  value = <<EOT
To connect to your VM, run:

  ssh -i ${local_file.user_private_key.filename} ${var.vm_username}@${google_compute_instance.debian_vm.network_interface[0].access_config[0].nat_ip}

EOT
}


