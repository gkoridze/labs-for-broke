#!/bin/bash
set -e

eval "$(jq -r '@sh "CONFIG64=\(.config64)"')"

BUTANE64=`echo $CONFIG64 | base64 -d | butane | base64`

jq -n --arg config "$BUTANE64" '{"base64":$config}'
