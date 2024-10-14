#!/bin/bash

IFS=':' read -r _ _ port ipab ipcd _ <<< "$(dig AAAA @1.1.1.1 +short $1)"
port=$((0x$port))
ipab=$((0x$ipab))
ipcd=$((0x$ipcd))
ipa=$(($ipab >> 8))
ipb=$(($ipab & 0xff))
ipc=$(($ipcd >> 8))
ipd=$(($ipcd & 0xff))

exec nc -w1 ${ipa}.${ipb}.${ipc}.${ipd} ${port}
