#!/bin/bash

IFS=':' read -r _ _ port ipab ipcd _ <<< "$(dig AAAA @1.0.0.1 +short $1)"
port=$((0x$port))
ipab=$((0x$ipab))
ipcd=$((0x$ipcd))
ipa=$(($ipab >> 8))
ipb=$(($ipab & 0xff))
ipc=$(($ipcd >> 8))
ipd=$(($ipcd & 0xff))

echo "Connecting to ${ipa}.${ipb}.${ipc}.${ipd}:${port}..."

exec nc -w1 ${ipa}.${ipb}.${ipc}.${ipd} ${port}
