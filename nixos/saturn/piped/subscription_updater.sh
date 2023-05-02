#!/usr/bin/env bash
set -euo pipefail
json=$(
    cat <<EOF
{
    "username": "$USERNAME",
    "password": "$PASSWORD"
}
EOF
)

token=$(curl --json "$json" --silent --request POST https://pipedapi.home.5kw.li/login | jq '.token' -r)

subscriptions=$(curl --silent --header "Authorization: $token" https://pipedapi.home.5kw.li/subscriptions | jq 'map(.url)|@tsv' -r)

for sub in $subscriptions; do
    curl --silent "https://pipedapi.home.5kw.li$sub" >/dev/null
    sleep 1
done
