#!/bin/zsh

setopt err_exit pipe_fail noclobber
umask 077

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <peer_ip> <endpoint> <gateway>" >&2
    exit 1
fi

ip=$1
endpoint=$2
gateway=$3

server_pub=$(grep PrivateKey /etc/wireguard/wg0.conf | awk '{ print $3 }' | wg pubkey)

priv=$(wg genkey)
pub=$(wg pubkey <<< $priv)
psk=$(wg genpsk)

> ${ip}.conf <<EOF
[Interface]
Address = $ip/32
PrivateKey = $priv

[Peer]
Endpoint = $endpoint
PublicKey = $server_pub
PresharedKey = $psk
AllowedIPs = $gateway/32
EOF

>> /etc/wireguard/wg0.conf <<EOF

[Peer]
PublicKey = $pub
PresharedKey = $psk
AllowedIPs = $ip/32
EOF
