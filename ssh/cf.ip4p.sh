#!/bin/bash

ZONE_ID=
DNS_RECORD_ID=
EMAIL=
KEY=
NAME=

public_ip=$4
public_port=$5
printf -v ip4p '2001::%04x:%02x%02x:%02x%02x' $public_port ${public_ip//./ }

curl https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID \
    -X PUT \
    -H 'Content-Type: application/json' \
    -H "X-Auth-Email: $EMAIL" \
    -H "Authorization: Bearer $KEY" \
    -d "{
      \"name\": \"${name}\",
      \"type\": \"AAAA\",
      \"content\": \"${ip4p}\",
      \"proxied\": false,
      \"ttl\": 60
    }"
