#!/usr/bin/env bash

[ -z "$DNS_CONFIG" ] && DNS_CONFIG='./config.json'; echo "DNS_CONFIG; $DNS_CONFIG"

if [ ! -e "$DNS_CONFIG" ]; then
  echo "Config file not found on disk"
  exit 1
fi

parse_config(){
  echo "$CONFIG" | jq -r "$1"
}

set_dns_subdomains() {
  CONFIG=$1; export CONFIG

  domain=$(parse_config '.domain'); echo "domain: $domain"
  pihole_address=$(parse_config '.pihole_address'); echo "pihole_address: $pihole_address"
  reverse_proxy=$(parse_config '.reverse_proxy'); echo "reverse_proxy: $reverse_proxy"
  pihole_secret_name=$(parse_config '.pihole_secret_name'); echo "pihole_secret_name: $pihole_secret_name"
  pihole_secret="${!pihole_secret_name}"

  sid=$(
    curl -s -X POST "$pihole_address/api/auth" \
        --data "{\"password\":\"$pihole_secret\"}" |
    jq -r '.session.sid'
  )

  for subdomain in $(parse_config .subdomains[]); do
    printf "Set $subdomain.$domain $reverse_proxy ..."

    response=$(
      curl -s -X PUT -w '%{http_code}' \
       "$pihole_address/api/config/dns/hosts/$reverse_proxy%20$subdomain.$domain?sid=$sid"
    )

    response_status="${response: -3}"
    response_json="${response::-3}"

if [ "$response_status" == '201' ] ||
   [ "$(echo "$response_json" | jq -r '.error.message')" == 'Item already present' ]; then
    echo 'OK'
else
    echo 'FAILED'
fi

unset response response_json response_status

  done
}

# Ready to be extended with multiple pihole servers...
set_dns_subdomains "$(cat "$DNS_CONFIG")"
