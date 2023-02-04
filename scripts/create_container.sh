#!/usr/bin/env bash

# shellcheck disable=SC2016
# shellcheck disable=SC2164

# Creates Proxmox containers from default template or
# user created template using the pct cli tool.
# This script is meant for automatiom platforms
# like Jenkins, TeamCity, etc.

set -x

script_path="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

if [ -f "$script_path/helpers.sh" ]; then
  source "$script_path/helpers.sh"

else
  printf 'helpers.sh file missing\n'
  exit 1
fi

log 'Starting container creation'

while getopts 'ab:c:d:g:h:i:m:n:o:p:r:s:t:uv' opt; do
  case $opt in
    a) tunnel_adapter='true' ;;
    b) bridge="${OPTARG:-vmbr0}" ;;
    c) cores="${OPTARG:-2}" ;;
    d) disk="${OPTARG:-8}" ;;
    g) gateway="$OPTARG" ;;
    h) hostname="$OPTARG" ;;
    i) id="$OPTARG" ;;
    m) mounts="$OPTARG" ;;
    n) nesting=1;;
    o) os_type="${OPTARG:-debian}" ;;
    p) password="$OPTARG" ;;
    r) ram="${OPTARG:-1024}"; swap="${OPTARG:-1024}" ;;
    s) storage="${OPTARG:-local}" ;;
    t) template="$OPTARG" ;;
    u) unprivileged='-unprivileged' ;;
    v) DEBUG='true' ;;
    *) log error "Invalid option:  -$OPTARG"; exit 1 ;;
  esac
done

nesting=${nesting:-0}
ip_address="$(echo "$gateway" | cut -d'.' -f1-3).$id"

log debug "bridge is: $bridge"
log debug "cores is: $cores"
log debug "disk is: $disk"
log debug "gateway is: $gateway"
log debug "hostname is: $hostname"
log debug "id is: $id"
log debug "ip_address is: $ip_address"
log debug "mounts is: $mounts"
log debug "os_type is: $os_type"
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
     -net "name=eth0,bridge=$bridge,firewall=1,gw=$gateway,ip=$ip_address/24,type=veth" \
     -rootfs "size=$disk" \
     -swap "$ram $unprivileged"
then log pass "Set container $id configuration"; fi

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
pct exec "$id" -- bash -c "echo '$password' | passwd --stdin root; $exec_commands"
pct reboot "$id"

log pass "Completed createion of container $id"
exit 0
