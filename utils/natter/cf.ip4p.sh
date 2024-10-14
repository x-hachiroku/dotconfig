#!/bin/bash

ZONE_ID=
RECORD=
EMAIL=
KEY=

public_ip=$4
public_port=$5

# IP intended to be splited to 4 arguments. Won't work with zsh
printf -v ip4p '2001::%04x:%02x%02x:%02x%02x' $public_port ${public_ip//./ }

curl https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD \
    -X PUT \
    -H 'Content-Type: application/json' \
    -H "X-Auth-Email: $EMAIL" \
    -H "Authorization: Bearer $KEY" \
    -d "{
      \"name\": \"ssh.rabbithouse\",
      \"type\": \"AAAA\",
      \"content\": \"${ip4p}\",
      \"proxied\": false,
      \"ttl\": 60
    }"
