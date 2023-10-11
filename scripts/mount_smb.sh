#!/usr/bin/with-contenv bash

# shellcheck shell=bash
# shellcheck disable=SC2216

# This script is for use with LinuxServers containers. It
# ensures cifs-utils is installed and mounts a samba share to
# a directory with the same name to root. It is expected that
# this file is in the containers /custom-cont-init.d/ path. It
# is advised to mount this path as read only from the host into
# the container

if [ ! -f '/smb_initalised' ]; then
  apt update && apt install cifs-utils -y
  mkdir "/$SMB_SHARENAME"
  echo "//$SMB_HOSTNAME/$SMB_SHARENAME /$SMB_SHARENAME cifs user=$SMB_USERNAME,password=$SMB_PASSWORD,uid=1000,gid=1000,vers=2.0  0  0" \
    >> /etc/fstab
  touch '/smb_initalised'
fi

mount -a
