#!/usr/bin/env bash

api_key=$1
distro=$(lsb_release -is); distro=${distro,,}
codename=$(lsb_release -cs)

case "$distro" in
  'debian')
    curl -fsSL "https://pkgs.tailscale.com/stable/$distro/$codename.gpg" | apt-key add -
    curl -fsSL "https://pkgs.tailscale.com/stable/$distro/$codename.list" | tee /etc/apt/sources.list.d/tailscale.list
  ;;

  'ubuntu')
    curl -fsSL "https://pkgs.tailscale.com/stable/$distro/$codename.noarmor.gpg" | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL "https://pkgs.tailscale.com/stable/$distro/$codename.tailscale-keyring.list" | tee /etc/apt/sources.list.d/tailscale.list
  ;;

  *)
    echo 'Unsuported distribution'
    exit 1
  ;;
esac

apt-get update -o Dir::Etc::sourcelist="sources.list.d/tailscale.list" \
  -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"

apt-get install tailscale -y

if [[ -n "$api_key" ]]; then
  tailscale u
fi

exit $?
