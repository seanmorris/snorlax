#!/usr/bin/env bash
## Update/Replace record
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
failIfCollecitonExists   "${FILENAME}";
failIfResourceNotFound   "${FILENAME}";

checkPerms "${REQUEST_METHOD}" "${FILENAME}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
	|| respondUnauthorized "Action not allowed.";

LOCK_FILE="/var/lock/snorlax_"$(sed "s#_#__#g;s#/#_#g" <<< "${FILENAME}");
LOCK_DIR=$(dirname "${LOCK_FILE}");

mkdir -p "${LOCK_DIR}";

(
	[ -f "${DIRECTORY}/.before-put.sh" ] && . ${DIRECTORY}/.before-put.sh

	flock -x "${FLOCK_ARGS}" 200 || exit 1;
	echo -ne "Status: 201 OK RESOURCE UPDATED\n";
	echo -ne "Content-type: text/plain\n";

	echo -ne "\n"

	tee "${FILENAME}" <<< "${CONTENT}";

	[ -f "${DIRECTORY}/.after-put.sh" ] && . ${DIRECTORY}/.after-put.sh

	# cd /app && make unmake > /dev/null;

	# make $(cat "/app/unmake/messages${REQUEST_PATH}.unmak") > /dev/null;

	true;

) 200> "${LOCK_FILE}" || {

	echo -ne "Status: 409 RESOURCE ACTIVE\n";
	echo -ne "Content-type: text/plain\n";
	echo -ne "Retry-After: 1\n";
	echo -ne "\n"

	echo -ne "409: CONFLICT! Resource is currently being modified by another user.\n";
	echo -ne "Please wait and try again.\n";
	echo -ne "\n"
};

exit 0;
