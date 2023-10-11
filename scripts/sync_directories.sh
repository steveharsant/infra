#!/usr/bin/env bash

# shellcheck disable=SC2139
# shellcheck disable=SC2086

# This script is used to sync the files from an internal drive to an external drive.
# A directory will be backed up only if the file '.nobackup' is not present.
#
# Example:
# /srv/Local-Infrastructure/shared/sync_directories.sh /mnt/disks/rd0/users/ /mnt/disks/ext1/users /mnt/disks/ext1/logs
# Note the trailing slash on the root_path

root_path=${1%/}
backup_path=${2%/}
log_path=${3%/}

if [ $# -eq 3 ]; then
  # root_path variable is parsed to replace / with _ characters
  log_file="$log_path/${root_path//\//_}-$(date -u +'%y-%m-%d_%H-%M').log"
  echo "Logging to fie: $log_file"
fi

log(){
  echo "$*"
  if [ -n "$log_file" ]; then echo "$*" >> "$log_file"; fi
}

log 'Sourcing /etc/environment'
source /etc/environment

if [ -z "$UPTIME_WEBHOOK" ]; then
  log 'Environment variable UPTIME_WEBHOOK is not set. Make sure you have set it in /etc/environment'
fi

# Create log directory if path is specified
if [ -n "$log_path" ]; then if [ -d "$log_path" ]; then
  log "Log directory $log_path already exists. Removing logs older than 90 days"
  find "$log_path/" -type f -mtime +90 -name '*.log' -execdir rm -- '{}' \;
else
  mkdir -p "$log_path"; log "Log directory $log_path created"
fi; fi

log 'Cleaning up log files older than 7 days'
find "$log_path" -name "*.log" -type f -mtime +7 -delete

log 'Discovering directories to exclude from backup'

# Populate directories array
directories=()
while IFS=  read -r -d $'\0'; do
  directories+=("$REPLY")
done < <(find "$root_path" -type d -print0)

# Build the rsync exclude list
for path in "${directories[@]}"; do
  if [ -f "$path/.nobackup" ]; then
    relative_path=${path#"$root_path"}
    relative_path=${relative_path//' '/'*'}
    exclude_list+="--exclude=$relative_path "
  fi
done

log "Executing backup with command: rsync -av $exclude_list --delete \"$root_path/\" \"$backup_path/\""
if rsync -av $exclude_list --delete "$root_path/" "$backup_path/" 2>&1 | tee -a "$log_file" 2> /dev/null; then
  curl "$UPTIME_WEBHOOK" 2> /dev/null
fi
