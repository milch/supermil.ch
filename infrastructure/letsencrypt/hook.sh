#!/bin/bash

deploy_challenge() {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    bundle exec fastlane upload upload_challenge:true
}

HANDLER="$1"; shift
if [[ "${HANDLER}" =~ ^(deploy_challenge)$ ]]; then
   "$HANDLER" "$@"
fi
