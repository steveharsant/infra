variable "proxmox_url" {
  type = string
}

variable "proxmox_id" {
  type = string
}

variable "proxmox_secret" {
  type      = string
  sensitive = true
}

variable "ssh_private_key_path" {
  type      = string
  sensitive = true
}
