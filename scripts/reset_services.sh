#!/usr/bin/env bash

# A dirty and lazy script to restart services rather than fix the root cause.
# I will fix the root cause soon(tm)...

docker_path='/data/docker'
media_path='/data/media'
downloads_path='/data/downloads'

set_permissions() {
  sudo chown -R steve:steve "$1"
  sudo chmod -R 777 "$1"
}

set_permissions "$media_path"

case "$1" in
  'emby')
    set_permissions "$docker_path/emby"
    sudo docker container restart emby
  ;;

  'arrs')
    for service in {'sonarr','radarr','prowlarr','bazarr'}; do
      set_permissions "$docker_path/$service"
      sudo docker container restart "$service"
    done
  ;;

  'qbit')
    set_permissions "$docker_path/qbit"
    set_permissions "$downloads_path"
    sudo docker container restart qbit
  ;;

  '')
    set_permissions "$downloads_path"
    for service in {'emby','sonarr','radarr','prowlarr','bazarr',qbit}; do
      set_permissions "$docker_path/$service"
      sudo docker container restart "$service"
    done
  ;;

esac
