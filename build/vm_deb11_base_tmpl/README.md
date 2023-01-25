# Debian 11 VM Base Template Build Files

*This directory contains the configuration for Packer to create a 'golden image' VM template using Proxmox.*

## What's Included

* 1 core, 2048M ram, 8G disk (qcow2)
* Debian 11 (Bullseye) preseed configuration:
  * UK/GB locale, keyboard, timezine, and apt mirror configuration
  * DHCP enabled network on default interface
  * Variablised hostname, domain, root password, and public key using `{{  }}` wrappers (ready for automation platforms to inject values using `sed` or similar)
  * Single lvm partition
  * Standard installation with openssh server (no GUI)
* cloud-init ready
* Open ssh server configuration with private key only configuration
* A small assortment of additional apt packages (see `files/provision.sh` script)
* My personal dotfiles
* Debian unattended upgrades preconfigured

## How To Use

* Duplicate the `credentials.pkr.hcl.tmpl` file and remove the `.tmpl` file extension
* Populate variables values in newly created `credentials.pkr.hcl` file
* If not using any automation platform (e.g. Jenkins, TeamCity), replace the values wrapped in `{{  }}` (including the brackets) in the `http/preseed.cfg` file
* Run with the command:

```shell
packer build -var-file='..\credentials.pkr.hcl' .
```
