data "yandex_compute_image" "ubuntu" {
  family = var.vm_image_family
}

resource "yandex_compute_instance" "web" {
  count       = 2
  name        = "redmine-web${count.index + 1}"
  platform_id = "standard-v2"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 15
    }
  }

  network_interface {
    subnet_id          = var.subnet_id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.webservers.id]
  }

  metadata = {
    ssh-keys  = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    user-data = <<-EOT
      #cloud-config
      users:
        - name: ${var.ssh_user}
          groups: sudo
          shell: /bin/bash
          sudo: ['ALL=(ALL) NOPASSWD:ALL']
          ssh_authorized_keys:
            - ${file(var.ssh_public_key_path)}
    EOT
  }
}
