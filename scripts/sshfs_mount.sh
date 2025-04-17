#!/usr/bin/env bash

set -e

[ -z "$1" ] && exit 1 || backup_name="$1"
[ -z "$2" ] && exit 1 || connection_string="$2"
[ -z "$3" ] && PRIVATE_KEY_PATH="${PRIVATE_KEY_PATH:-}" || PRIVATE_KEY_PATH="$3"
[ -z "$PRIVATE_KEY_PATH" ] && exit 1

echo 'Parsed script arguments successfully'

if ! [ -s "$PRIVATE_KEY_PATH" ]; then
  echo "Private key not found" && exit 1
fi

apk add sshfs
echo 'sshfs dependency met'

mkdir -p "/mnt/$backup_name"
sshfs -o IdentityFile="$PRIVATE_KEY_PATH",StrictHostKeyChecking=no \
      "$connection_string" "/mnt/$backup_name"

echo "sshfs path successfully mounted from '$connection_string' to '/mnt/$backup_name'"
