#!/usr/bin/env bash

# shellcheck disable=SC2016
# shellcheck disable=SC2164

# Creates Proxmox containers from default template or
# user created template using the pct cli tool.
# This script is meant for automatiom platforms
# like Jenkins, TeamCity, etc.

set -e

script_path="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

if [ -f "$script_path/helpers.sh" ]; then
  source "$script_path/helpers.sh"

else
  printf 'helpers.sh file missing\n'
  exit 1
fi

log 'Starting container creation'

while getopts 'ab:c:d:g:h:i:m:no:p:r:s:t:uv' opt; do
  case $opt in
    a) tunnel_adapter='true' ;;
    b) bridge="$OPTARG" ;;
    c) cores="$OPTARG" ;;
    d) disk="$OPTARG" ;;
    g) gateway="$OPTARG" ;;
    h) hostname="$OPTARG" ;;
    i) id="$OPTARG" ;;
    m) mounts="$OPTARG" ;;
    n) nesting=1;;
    p) password="$OPTARG" ;;
    r) ram="$OPTARG"; swap="$OPTARG" ;;
    s) storage="$OPTARG" ;;
    t) template="$OPTARG" ;;
    u) unprivileged='-unprivileged' ;;
    v) DEBUG='true' ;;
    *) log error "Invalid option:  -$OPTARG"; exit 1 ;;
  esac
done

# Set defaults if missing
bridge=${bridge:-vmbr0}
cores=${cores:-2}
disk=${disk:-8}
nesting=${nesting:-0}
ram=${ram:-1024}
swap=${swap:-1024}
storage=${storage:-local}
ip_address="$(echo "$gateway" | cut -d'.' -f1-3).$id"

log debug "bridge is: $bridge"
log debug "cores is: $cores"
log debug "disk is: $disk"
log debug "gateway is: $gateway"
log debug "hostname is: $hostname"
log debug "id is: $id"
log debug "ip_address is: $ip_address"
log debug "mounts is: $mounts"
log debug "ram is: $ram"
log debug "storage is: $storage"
log debug "swap is: $swap"
log debug "template is: $template"


if [[ $template =~ [0-9] ]]; then

  # Clone from golden image
  log "Cloning template $template to $id"

  if pct clone "$template" "$id" \
       -full \
       -hostname "$hostname" \
       -storage "$storage"
  then log pass "Created container with id $id"; fi

else
  # Create from default image
  log "Creating container $id from template $template"

  if pct create "$id" "$template" \
       -hostname "$hostname" \
       -storage "$storage"
  then log pass "Created container with id $id"; fi

fi

log 'Provisioning resources and configuration'

if pct set "$id" \
     -arch amd64 \
     -cores "$cores" \
     -features "nesting=$nesting" \
     -hostname "$hostname" \
     -memory "$ram" \
     --net0 "name=eth0,bridge=$bridge,firewall=1,gw=$gateway,ip=$ip_address/24,type=veth" \
     -swap "$ram" "$unprivileged"
then log pass "Set container $id configuration"; fi

if pct resize "$id "rootfs "${disk}G"
then log pass "Resized root filesystem to $disk"; fi

# Mounts
# Each mount should be seperated by a semi-colon(;)
# Each mount syntax is: /path/on/container,/path/on/host
IFS=';'
i=0

for mount in $mounts; do
  to=$(echo "$mount "| cut -d',' -f1)
  from=$(echo "$mount" | cut -d',' -f2)
  log "Mounting $from to $to"

  if pct set "$id" -mp$i "mp=$mount"
  then log pass 'Bind mount successful'; fi

  ((i=i+1))
done

if [[ -n "$tunnel_adapter" ]]; then
  log 'Configuring tunnel adaptor'

  if [[ -n "$unprivileged" ]]; then
    echo 'lxc.cgroup.devices.allow: c 10:200 rwm' >> "/etc/pve/lxc/$id"
    echo 'lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file' >> "/etc/pve/lxc/$id"

  else
    echo 'lxc.cgroup2.devices.allow: c 10:200 rwm' >> "/etc/pve/lxc/$id"
    echo 'lxc.hook.autodev: sh -c "modprobe tun; cd ${LXC_ROOTFS_MOUNT}/dev; mkdir net; mknod net/tun c 10 200; chmod 0666 net/tun"' >> "/etc/pve/lxc/$id"
    exec_commands="cd /dev; mkdir net; mknod net/tun c 10 200; chmod 0666 net/tun;"
  fi
fi

pct start "$id"
sleep 10
pct exec "$id" -- bash -c "echo 'root:$password' | chpasswd; $exec_commands"
pct reboot "$id"

log pass "Completed createion of container $id"
exit 0
