#!/usr/bin/env bash

# shellcheck source=../lib/crypto.sh
. "$(dirname "${0}")"/request.sh

set -x;

LOCATION=${1:-};

request "OPTIONS" "$LOCATION" "/dev/null" "text/stream";
