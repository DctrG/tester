output "vm_ip_address" {
value = google_compute_instance.debian_vm.network_interface[0].access_config[0].nat_ip
}

output "ssh_connection" {
  value = <<EOT
To connect to your VM, run:

  ssh -i ${local_file.user_private_key.filename} ${var.vm_username}@${google_compute_instance.debian_vm.network_interface[0].access_config[0].nat_ip}

EOT
}