#!/usr/bin/env bash
## Create record
# shellcheck source=../lib/init.sh
set -a; . "$(dirname "${0}")/../lib/init.sh"; set +a;

[[ -z "${HTTP_RSA_PUBLIC_KEY}" ]] && respondUnauthorized;
[[ -z "${HTTP_RSA_SIGNATURE}" ]] && respondUnauthorized;

set -ux;

failOnRequestDotFile;

CONTENT=$(cat);

verifySignature "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_SIGNATURE}" "${CONTENT}"\
	|| respondUnauthorized;

verifyFingerprint "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_SIGNATURE}" "${CONTENT}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
	|| respondUnauthorized "Fingerprint verification failed.";

failIfCollectionNotFound "${DIRECTORY}";
failIfCollecitonExists   "${FILENAME}";
failIfResourceExists     "${FILENAME}";

checkPerms "${REQUEST_METHOD}" "${FILENAME}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
	|| respondUnauthorized "Action not allowed.";

LOCK_FILE="/var/lock/sycamore${FILENAME}";
LOCK_DIR=$(dirname "${LOCK_FILE}");

mkdir -p "${LOCK_DIR}";

(
	flock -x "${FLOCK_ARGS}" 200 || exit 1;
	echo -ne "Status: 201 OK RESOURCE CREATED\n";
	echo -ne "Content-type: text/plain\n";

	echo -ne "\n"

	tee "${FILENAME}" <<< "${CONTENT}";

	# cd /app && make unmake > /dev/null;

	# make $(cat "/app/unmake/messages${REQUEST_PATH}.unmak") > /dev/null;

	true;

) 200> "${LOCK_FILE}" || {

	echo -ne "Status: 409 RESOURCE ACTIVE\n";
	echo -ne "Content-type: text/plain\n";
	echo -ne "Retry-After: 1\n";
	echo -ne "\n"

	echo -ne "409: ACTIVE! Resource is currently being modified by another user.\n";
	echo -ne "Please wait and try again.\n";
	echo -ne "\n"
};

exit 0;
