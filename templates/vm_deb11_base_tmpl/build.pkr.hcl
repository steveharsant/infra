build {

  name    = "vm-deb11-base-tmpl"
  sources = ["source.proxmox.deb11"]

  # Provisioning

  ## Create paths for config files
  provisioner "shell" {
    inline = [
      "mkdir -p /etc/cloud/cloud.cfg.d",
      "mkdir -p /etc/systemd/system/apt-daily.timer.d",
      "mkdir -p /etc/systemd/system/apt-daily-upgrade.timer.d"
    ]
  }

  ## Proxmox cloud-init config
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/etc/cloud/cloud.cfg.d/99-pve.cfg"
  }

  ## Unattended upgrades - config
  provisioner "file" {
    source      = "files/50unattended-upgrades"
    destination = "/etc/apt/apt.conf.d/50unattended-upgrades"
  }

  ## Unattended upgrades - update timer
  provisioner "file" {
    source      = "files/update-override.conf"
    destination = "/etc/systemd/system/apt-daily.timer.d/override.conf"
  }

  ## Unattended upgrades - upgrade timer
  provisioner "file" {
    source      = "files/upgrade-override.conf"
    destination = "/etc/systemd/system/apt-daily-upgrade.timer.d/override.conf"
  }

  ## Copy sshd config
  provisioner "file" {
    source      = "files/sshd_config"
    destination = "/etc/ssh/sshd_config"
  }

  ##  Run provisioning script
  provisioner "shell" {
    script       = "files/provision.sh"
    pause_before = "10s"
    timeout      = "10s"
  }
}
