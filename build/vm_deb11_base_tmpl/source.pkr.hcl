source "proxmox" "deb11" {

  # Provisioning Config
  cloud_init              = true
  cloud_init_storage_pool = "local"
  http_directory          = "http"
  http_port_min           = 8802
  http_port_max           = 8802

  # vHost Details
  proxmox_url              = "${var.proxmox_url}"
  username                 = "${var.proxmox_id}"
  token                    = "${var.proxmox_secret}"
  insecure_skip_tls_verify = true

  # Source OS Details
  iso_url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.6.0-amd64-netinst.iso"
  iso_checksum     = "e482910626b30f9a7de9b0cc142c3d4a079fbfa96110083be1d0b473671ce08d"
  iso_storage_pool = "local"
  unmount_iso      = true

  # VM Config
  node                 = "vhost"
  vm_id                = "899"
  vm_name              = "vm-deb11-base-tmpl"
  template_description = "Base Debian 11 VM image"

  cores           = "1"
  memory          = "2048"
  qemu_agent      = true
  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size         = "8G"
    format            = "qcow2"
    storage_pool      = "local"
    storage_pool_type = "lvm"
    type              = "virtio"
  }

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = "false"
  }

  # Boot commands
  boot_command = [
    "a<enter>",
    "a<enter>",
    "<wait45>",
    # "http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<enter>"
    # Uncomment to use external http server, set ip,
    # and comment out the above http line
    "http://192.168.5.111:8802/preseed.cfg<enter>"
  ]

  boot      = "c"
  boot_wait = "30s"

  # ssh connection config
  ssh_username         = "root"
  ssh_private_key_file = "${var.ssh_private_key_path}"
  ssh_timeout          = "20m"
}
