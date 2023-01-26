#!/usr/bin/env bash

apt-get update
apt-get upgrade -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" -y

apt-get install \
  apt-transport-https apt-listchanges unattended-upgrades cifs-utils \
  curl git gnupg2 htop lsb-release iotop jq ncdu screen unzip vim zip -y

# Configure dotfiles
pushd /srv/ || return
git clone https://github.com/steveharsant/dotfiles.git

cat <<EOF >> /root/.bashrc
# Source personal customisations from github.com/steveharsant/dotfiles
dotfiles_path='/srv/dotfiles'
dotfiles=( \$( ls \$dotfiles_path -a | grep bash ) )
for dotfile in "\${dotfiles[@]}"; do
  source "\$dotfiles_path/\$dotfile"
done
EOF

# Reset machine ID (Useful for templates)
truncate -s 0 /etc/machine-id

# apt cleanup
apt -y autoremove --purge
apt -y clean
apt -y autoclean

# cloud-init preperation
cloud-init clean
rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
sync

# Enable unattended upgrades (Config applied in packers build.pkr.hcl file)
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades
