#!/bin/zsh

tracker=$1
infohash=$(sed 's/../%&/g' <<< ${2:l})

curl -G $tracker \
  -A "Transmission/2.94" \
  -d "peer_id=-TR2940-73b64bd89c2c" \
  -d "info_hash=$infohash" \
  -d "port=58654" \
  -d "uploaded=0" \
  -d "downloaded=0" \
  -d "left=0" \
  -d "compact=1" \
  -d "numwant=50" \
  | xxd -p
