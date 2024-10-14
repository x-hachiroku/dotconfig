#!/usr/bin/bash

if [ -n "$1" ]; then host="$1"; else host=10; fi

iptables -t nat -F MRDP
iptables -t nat -A MRDP -p tcp -j DNAT --to-destination 10.6.6.$host:3389
iptables -t nat -A MRDP -p udp -j DNAT --to-destination 10.6.6.$host:3389
