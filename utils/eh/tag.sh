APIUID=
APIKEY=''
TAG=''

function tag() {
curl --cookie "$(jq -r 'to_entries | map("\(.key)=\(.value)") | join("; ")' ~/.config/cookies/eh.json)" https://api.e-hentai.org/api.php --json @- <<EOF
{
    "apiuid": $APIUID,
    "apikey": "$APIKEY",
    "method": "taggallery",
    "gid": $1,
    "token": "$2",
    "tags": "$TAG",
    "vote": 1
}
EOF
}
