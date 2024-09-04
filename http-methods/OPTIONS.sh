#!/usr/bin/env bash
## Serve metadata for a record.
# shellcheck source=../lib/init.sh
set -a; . "$(dirname "${0}")/../lib/init.sh"; set +a;

[[ -z "${HTTP_RSA_PUBLIC_KEY}" ]] && respondUnauthorized;
[[ -z "${HTTP_RSA_SIGNATURE}" ]] && respondUnauthorized;

failOnRequestDotFile;

CONTENT=$(cat);

verifySignature "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_SIGNATURE}" "${CONTENT}"\
	|| respondUnauthorized "Signature verification failed.";

verifyFingerprint "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_SIGNATURE}" "${CONTENT}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
	|| respondUnauthorized "Fingerprint verification failed.";

failIfCollectionNotFound "${DIRECTORY}";
failIfResourceNotFound   "${FILENAME}";

# checkPerms "${REQUEST_METHOD}" "${FILENAME}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
# 	|| respondUnauthorized "Action not allowed.";

LOCK_FILE="/var/lock/snorlax_"$(sed "s#_#__#g;s#/#_#g" <<< "${FILENAME}");
LOCK_DIR=$(dirname "${LOCK_FILE}");

mkdir -p "${LOCK_DIR}";

(
	flock -s "${FLOCK_ARGS}" 200 || exit 1;
	echo -ne "Status: 204 NO CONTENT\n";
	echo -ne "Content-type: text/plain\n";
	echo -ne "Allow: OPTIONS, GET, HEAD, POST, PATCH, PUT DELETE\n";
	echo -ne "Filename: ${RESOURCE}\n";
	echo -ne "\n"
) 200> "${LOCK_FILE}" || {
	echo -ne "Status: 409 RESOURCE ACTIVE\n";
	echo -ne "Content-type: text/plain\n";
	echo -ne "Retry-After: 1\n";
	echo -ne "\n"
	echo -ne "409: ACTIVE! Resource is currently being modified by another user.\n";
	echo -ne "Please wait and try again.\n";
	echo -ne "\n"
};
