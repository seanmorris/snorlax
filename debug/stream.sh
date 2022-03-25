#!/usr/bin/env bash

# shellcheck source=../lib/crypto.sh
. "$(dirname "${0}")"/request.sh

set -x;

LOCATION=${1:-};
FILENAME=${2:-/dev/null};

request "GET" "$LOCATION" "/dev/null" 1;