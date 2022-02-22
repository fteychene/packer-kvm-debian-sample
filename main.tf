terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = data.template_file.user_data.rendered
}

variable "ssh-key" {
    type = string
    default = ""
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    ssh-key = var.ssh-key
  }
}


provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "debian" {
  name   = "debian.qcow2"
  pool   = "default"
  source = "file://${path.cwd}/output/debian.qcow2"
  format = "qcow2"
}

resource "libvirt_network" "tf" {
  name      = "tf"
  domain    = "tf.local"
  mode      = "nat"
  addresses = ["10.0.100.0/24"]
}

resource "libvirt_domain" "worker" {
  name   = "debian-immutable"
  memory = "2048"
  vcpu   = 2

  network_interface {
    network_id     = libvirt_network.tf.id
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.debian.id
  }
}

output "ip" {
  value = libvirt_domain.worker.network_interface.0.addresses.0
}