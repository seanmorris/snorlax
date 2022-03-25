#!/usr/bin/env bash
[[ -f /app/.env ]] && { set -a; . /app/.env; set +a; };

set -x;

## Includes...

# shellcheck source=../lib/crypto.sh
. "$(dirname "${0}")"/../lib/crypto.sh

# shellcheck source=../lib/perm-checks.sh
. "$(dirname "${0}")"/../lib/perm-checks.sh

# shellcheck source=../lib/request-checks.sh
. "$(dirname "${0}")"/../lib/request-checks.sh

# shellcheck source=../lib/responses.sh
. "$(dirname "${0}")"/../lib/responses.sh

[ -z "${REQUEST_URI}" ] || [ "${REQUEST_URI}" == "/" ] && {

	respondChallengeString;
}

PUBLIC_ROOT='/app/public';

REQUEST_PATH=$(cut -d'?' -f 1 <(echo "${REQUEST_URI}"));
QUERY_STRING=$(cut -d'?' -f 2 <(echo "${REQUEST_URI}"));

## Resolve traversals/links and ensure we're
## still in a valid directory

FILENAME=$(readlink -f "${PUBLIC_ROOT}${REQUEST_PATH}");

test "${FILENAME##${PUBLIC_ROOT}}" != "${FILENAME}" || {
	respondNotFound $REQUEST_PATH;
	exit 1;
}

## Request vars

DIRECTORY=$(dirname "${FILENAME}");
RESOURCE=${REQUEST_URI#\/};
COLLECTION=$(dirname "${RESOURCE}");

## Config defaults...

LOCK_WAIT=${LOCK_WAIT:-0};

if [[ -z ${LOCK_WAIT} ]]; then
	FLOCK_ARGS="-n";
else
	FLOCK_ARGS="-w ${LOCK_WAIT}";
fi

EVENT_WAIT=${EVENT_WAIT:-5};

TIMEOUT_ARGS="-k ${EVENT_WAIT} ${EVENT_WAIT}s"

[[ ${EVENT_WAIT} == -1 ]] && {
	TIMEOUT_ARGS=""
}
