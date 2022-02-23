# QEMU Debian packer image builder 

## Build from cloud-init Debian

```
❯ cloud-localds cloud-init/seed.img cloud-init/userdata.cfg 

❯ packer build debian-cloud-init.pkr.hcl
...
==> Wait completed after 7 minutes 24 seconds

==> Builds finished. The artifacts of successful builds are:
--> qemu.debian: VM files in directory: output
--> qemu.debian: VM files in directory: output
```

You can edit the cloud-init configuration of the build machine by recreating the [cloud-init/seed.img] with your custom userdata.  
Here is the [userdata.cfg](cloud-init/userdata.cfg) used to create the already defined seed.img.

## Build from netinst ISO

Configuration script is copied from [multani/packer-qemu-debian](https://github.com/multani/packer-qemu-debian). 
Thx a lot for this template to configure cloud-image to be ran locally easily.

```
❯ packer build debian-netinst.pkr.hcl
...
==> Wait completed after 6 minutes 5 seconds

==> Builds finished. The artifacts of successful builds are:
--> qemu.debian: VM files in directory: output
--> qemu.debian: VM files in directory: output
```

## Run a VM with builded image


To run the image :
```bash
❯ terraform apply -auto-approve
... 
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

ip = "10.0.100.XXX"
```

A VM is booted with the image built with packer, you can connect with `debian:debian` on the output ip by terraform.

```
❯ ssh debian@10.0.100.XXX
debian@10.0.100.XXX's password:
Linux localhost 5.10.0-11-amd64 #1 SMP Debian 5.10.92-1 (2022-01-18) x86_64
██╗    ██╗███████╗██╗      ██████╗ ██████╗ ███╗   ███╗███████╗
██║    ██║██╔════╝██║     ██╔════╝██╔═══██╗████╗ ████║██╔════╝
██║ █╗ ██║█████╗  ██║     ██║     ██║   ██║██╔████╔██║█████╗
██║███╗██║██╔══╝  ██║     ██║     ██║   ██║██║╚██╔╝██║██╔══╝
╚███╔███╔╝███████╗███████╗╚██████╗╚██████╔╝██║ ╚═╝ ██║███████╗
 ╚══╝╚══╝ ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝

██╗███╗   ███╗███╗   ███╗██╗   ██╗████████╗ █████╗ ██████╗ ██╗     ███████╗
██║████╗ ████║████╗ ████║██║   ██║╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝
██║██╔████╔██║██╔████╔██║██║   ██║   ██║   ███████║██████╔╝██║     █████╗
██║██║╚██╔╝██║██║╚██╔╝██║██║   ██║   ██║   ██╔══██║██╔══██╗██║     ██╔══╝
██║██║ ╚═╝ ██║██║ ╚═╝ ██║╚██████╔╝   ██║   ██║  ██║██████╔╝███████╗███████╗
╚═╝╚═╝     ╚═╝╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝

debian@localhost:~$
```

## Misc

> I have an error when running Terraform `could not open disk image /var/lib/libvirt/images/debian.qcow2: Permission denied`

I you are on Ubuntu please try to set `security_driver = "none"` in `/etc/libvirt/qemu.conf` and restart you `libvirt` service (`systemctl restart libvirtd`)