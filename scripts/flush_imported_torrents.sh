#! /usr/bin/env bash

url='http://localhost:8112/api/v2'

auth_response=$(curl -i \
                     --header "Referer: $url" \
                     --data "username=$QBIT_USER&password=$QBIT_PASS" \
                     "$url/auth/login")

sid=$(echo "$auth_response" |
        grep -i 'Set-Cookie: SID=' |
        cut -d '=' -f2 |
        cut -d ';' -f1)

imported_torrents=$(curl --cookie "SID=$sid" \
                         "$url/torrents/info" |
                     jq '[.[] | select(.category | test("^sonarr-imported$|^radarr-imported$"))]')

if [ "$imported_torrents" == '[]' ]; then
  exit 0
fi

printf "Imported torrents found: \n$(echo "$imported_torrents"  | jq -r '.[].name')\n
Removing imported torrents and associated data\n
"

torrent_hashes=$(echo "$imported_torrents" |
                  jq -r '[.[].hash] | join("|")')

if ! curl --silent --cookie "SID=$sid" \
  --data-urlencode "hashes=$torrent_hashes" \
  --data-urlencode "deleteFiles=true" \
  "$url/torrents/delete";
then
    echo 'Failed to delete imported torrent entries'
    exit 1
fi
