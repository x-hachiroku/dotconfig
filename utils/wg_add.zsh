#!/bin/zsh

priv=$(wg genkey)
pub=$(wg pubkey <<< $priv)
psk=$(wg genpsk)

ip=$1
endpoint=$2
gateway=$3

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <peer_ip> <endpoint> <gateway>"
    exit 1
fi

>> /etc/wireguard/wg0.conf <<EOF

[Peer]
PublicKey = $pub
PresharedKey = $psk
AllowedIPs = $ip/32
EOF


> ${ip}.conf <<EOF
[Interface]
Address = $ip/32
PrivateKey = $priv

[Peer]
Endpoint = $endpoint
PublicKey = $pub
PresharedKey = $psk
AllowedIPs = $gateway/32
EOF


