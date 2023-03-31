variable "output_dir" {
  type    = string
  default = "output"
}

variable "output_name" {
  type    = string
  default = "debian.qcow2"
}

variable "source_checksum_url" {
  type    = string
  default = "file:https://cloud.debian.org/images/cloud/bullseye/20220121-894/SHA512SUMS"
}

variable "source_qcow" {
  type    = string
  default = "https://cloud.debian.org/images/cloud/bullseye/20220121-894/debian-11-generic-amd64-20220121-894.qcow2"
}

variable "password" {
  type    = string
  default = "debian"
}

variable "username" {
  type    = string
  default = "debian"
}

build {
  sources = ["source.qemu.debian"]

  provisioner "ansible" {
    playbook_file           = "ansible/playbook.yml"
    ansible_ssh_extra_args  = ["-o IdentitiesOnly=yes"]
    extra_arguments = [ "--scp-extra-args", "'-O'" ]
    keep_inventory_file     = true
  }

  post-processor "manifest" {
    keep_input_artifact = true
  }
}


source qemu "debian" {
  iso_url      = "${var.source_qcow}"
  iso_checksum = "${var.source_checksum_url}"
  disk_image   = true

  cpus = 1
  memory      = 2048
  disk_size   = 8000
  accelerator = "kvm"

  headless = true

  # SSH ports to redirect to the VM being built
  host_port_min    = 2222
  host_port_max    = 2229
  ssh_username     = "${var.username}"
  ssh_password     = "${var.password}"
  ssh_wait_timeout = "1000s"

  shutdown_command = "sudo -S /sbin/shutdown -hP now"

  # Builds a compact image
  disk_compression   = true
  disk_discard       = "unmap"
  skip_compaction    = false
  disk_detect_zeroes = "unmap"

  format           = "qcow2"
  output_directory = "${var.output_dir}"
  vm_name          = "${var.output_name}"

  boot_wait    = "1s"
  qemuargs = [
        ["-m", "2048M"],
        ["-smp", "2"],
        ["-cdrom", "cloud-init/seed.img"]
      ]
}
