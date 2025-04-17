#!/usr/bin/env bash

[ -z "$BACKUP_NAME" ] && exit 1
[ -z "$BACKUP_PATH" ] && exit 1
[ -z "$REMOTE_USER" ] && exit 1
[ -z "$REMOTE_HOST" ] && exit 1
[ ! -s "$SSHKEY_PATH" ] && exit 1
connection_string="$REMOTE_USER@$REMOTE_HOST:$BACKUP_PATH"

apk add sshfs
mkdir -p "/$BACKUP_NAME"
sshfs -o IdentityFile="$SSHKEY_PATH",StrictHostKeyChecking=no \
      "$connection_string" "/$BACKUP_NAME"

exit 0
