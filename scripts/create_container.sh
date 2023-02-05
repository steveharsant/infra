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

while getopts 'ab:c:d:g:h:i:m:no:p:r:s:St:uv' opt; do
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
    S) start_on_boot=1 ;;
    t) template="$OPTARG" ;;
    u) unprivileged='true' ;;
    v) DEBUG='true' ;;
    *) log fail "Invalid option:  -$OPTARG"; exit 1 ;;
  esac
done

# Set defaults if missing
bridge=${bridge:-vmbr0}
cores=${cores:-2}
disk=${disk:-8}
ip_address="$(echo "$gateway" | cut -d'.' -f1-3).$id"
nesting=${nesting:-0}
ram=${ram:-1024}
start_on_boot=${start_on_boot:-0}
storage=${storage:-local}
swap=${swap:-1024}
unprivileged=${unprivileged:-false}

log debug "bridge is: $bridge"
log debug "cores is: $cores"
log debug "disk is: $disk"
log debug "gateway is: $gateway"
log debug "hostname is: $hostname"
log debug "id is: $id"
log debug "ip_address is: $ip_address"
log debug "mounts is: $mounts"
log debug "nesting is: $nesting"
log debug "ram is: $ram"
log debug "start_on_boot is: $start_on_boot"
log debug "storage is: $storage"
log debug "swap is: $swap"
log debug "template is: $template"

if [[ "$unprivileged" == 'true' ]]; then
  log warn '-u is currently unused and reserved for future use.'
fi

if [[ $template =~ [0-9] ]]; then

  # Clone from golden image
  log "Cloning template $template to $id"

  if pct clone "$template" "$id" \
       -full \
       -hostname "$hostname" \
       -storage "$storage"  &> /dev/null
  then log pass "Created container with id $id"
  else log fail "Failed to create container with id $id"; fi

else
  # Create from default image
  log "Creating container $id from template $template"

  if pct create "$id" "$template" \
       -hostname "$hostname" \
       -storage "$storage"  &> /dev/null
  then log pass "Created container with id $id"
  else log fail "Failed to create container with id $id"; fi

fi

log 'Provisioning resources and configuration'

if pct set "$id" \
     -arch amd64 \
     -cores "$cores" \
     -features "nesting=$nesting" \
     -hostname "$hostname" \
     -memory "$ram" \
     --net0 "name=eth0,bridge=$bridge,firewall=1,gw=$gateway,ip=$ip_address/24,type=veth" \
     --onboot="$start_on_boot" \
     -swap "$ram"  &> /dev/null
then log pass "Set container $id configuration"
else log fail "Failed to configure container $id"; fi

log "Resizng root filesystem to ${disk}G"

if pct resize "$id" rootfs "${disk}G"  &> /dev/null
then log pass "Resized root filesystem to ${disk}G"
else log fail "Failed to resize root filesustem for container $id"; fi

# Mounts
# Each mount should be seperated by a semi-colon(;)
# Each mount syntax is: /path/on/container,/path/on/host
IFS=';'

for mount in $mounts; do
  to=$(echo "$mount "| cut -d',' -f1)
  from=$(echo "$mount" | cut -d',' -f2)
  log "Mounting $from to $to"

  if pct set "$id" -mp$i "mp=$mount"
  then log pass 'Bind mount successful'
  else log fail 'Failed to create bind mount'; fi

  ((i=i+1))
done

if [[ -n "$tunnel_adapter" ]]; then
  log 'Configuring tunnel adaptor'

  if [[ -n "$unprivileged" ]]; then
    echo 'lxc.cgroup.devices.allow: c 10:200 rwm' >> "/etc/pve/lxc/$id" || ((f=f+1))
    echo 'lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file' >> "/etc/pve/lxc/$id" || ((f=f+1))

  else
    echo 'lxc.cgroup2.devices.allow: c 10:200 rwm' >> "/etc/pve/lxc/$id" || ((f=f+1))
    echo 'lxc.hook.autodev: sh -c "modprobe tun; cd ${LXC_ROOTFS_MOUNT}/dev; mkdir net; mknod net/tun c 10 200; chmod 0666 net/tun"' \
      >> "/etc/pve/lxc/$id" || ((f=f+1))
    exec_commands="cd /dev; mkdir net; mknod net/tun c 10 200; chmod 0666 net/tun;"
  fi

  if (( "$f" > 0 )); then
    log fail "$f errors occured configuring tunnel adapter"
  fi
fi

log 'Starting container'
pct start "$id" &> /dev/null
sleep 10

log 'Executing OS configuration'
if pct exec "$id" -- bash -c "echo 'root:$password' | chpasswd; $exec_commands"
then log pass 'Completed OS configuration'
else log fail 'Failed to configure OS'; fi

log 'Rebooting container for all changes to take place'
pct reboot "$id"

log pass "Completed createion of container $id"
exit 0
