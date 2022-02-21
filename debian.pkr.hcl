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
  default = "file:https://cdimage.debian.org/cdimage/release/11.2.0/amd64/iso-cd/SHA256SUMS"
}

variable "source_iso" {
  type    = string
  default = "https://cdimage.debian.org/cdimage/release/11.2.0/amd64/iso-cd/debian-11.2.0-amd64-netinst.iso"
}

variable "ssh_password" {
  type    = string
  default = "debian"
}

variable "ssh_username" {
  type    = string
  default = "debian"
}

# "timestamp" template function replacement
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}


build {
  description = <<EOF
This builder builds a QEMU image from a Debian "netinst" CD ISO file.
It contains a few basic tools and can be use as a "cloud image" alternative.
EOF

  sources = ["source.qemu.debian"]

  provisioner "file" {
    source      = "configure/configure-qemu-image.sh"
    destination = "/tmp/configure-qemu-image.sh"
  }

  provisioner "shell" {
    inline = [
      "sh -cx 'sudo bash /tmp/configure-qemu-image.sh'"
    ]
  }

  provisioner "file" {
    source      = "configure/install-ansible.sh"
    destination = "/tmp/install-ansible.sh"
  }

  provisioner "shell" {
    inline = [
      "sh -cx 'sudo bash /tmp/install-ansible.sh'"
    ]
  }


  provisioner "ansible-local" {
    playbook_file = "ansible/playbook.yml"
    playbook_dir = "ansible"
  }

  post-processor "manifest" {
    keep_input_artifact = true
  }
}


source qemu "debian" {
  iso_url      = "${var.source_iso}"
  iso_checksum = "${var.source_checksum_url}"

  cpus = 1
  # The Debian installer warns with a dialog box if there's not enough memory
  # in the system.
  memory      = 1000
  disk_size   = 8000
  accelerator = "kvm"

  headless = true

  http_directory = "configure"
  http_port_min  = 9990
  http_port_max  = 9999

  # SSH ports to redirect to the VM being built
  host_port_min = 2222
  host_port_max = 2229
  # This user is configured in the preseed file.
  ssh_password     = "${var.ssh_password}"
  ssh_username     = "${var.ssh_username}"
  ssh_wait_timeout = "1000s"

  shutdown_command = "echo '${var.ssh_password}'  | sudo -S /sbin/shutdown -hP now"

  # Builds a compact image
  disk_compression   = true
  disk_discard       = "unmap"
  skip_compaction    = false
  disk_detect_zeroes = "unmap"

  format           = "qcow2"
  output_directory = "${var.output_dir}"
  vm_name          = "${var.output_name}"

  boot_wait = "1s"
  boot_command = [
    "<down><tab>", # non-graphical install
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "language=en locale=en_US.UTF-8 ",
    "country=CH keymap=fr ",
    "hostname=packer domain=test ", # Should be overriden after DHCP, if available
    "<enter><wait>",
  ]
}
