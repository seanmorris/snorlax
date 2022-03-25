#!/usr/bin/env bash
## Delete record
# shellcheck source=../lib/init.sh
set -a; . "$(dirname "${0}")/../lib/init.sh"; set +a;

[[ -z "${HTTP_RSA_PUBLIC_KEY}" ]] && respondUnauthorized;
[[ -z "${HTTP_RSA_SIGNATURE}" ]] && respondUnauthorized;

failOnRequestDotFile;

CONTENT="$(cat)";

verifySignature "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_SIGNATURE}" "${CONTENT}"\
	|| respondUnauthorized "Signature verification failed.";

verifyFingerprint "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_SIGNATURE}" "${CONTENT}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
	|| respondUnauthorized "Fingerprint verification failed.";

failIfCollectionNotFound "${DIRECTORY}";
failIfResourceNotFound   "${FILENAME}";

checkPerms "${REQUEST_METHOD}" "${FILENAME}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
	|| respondUnauthorized "Action not allowed.";

[[ -d ${FILENAME} ]] && {
	failIfCollectionNotEmpty "${RESOURCE}";

	rmdir "${FILENAME}";

	echo -ne "Status: 200 OK COLLECTION REMOVED\n";
	echo -ne "Content-type: text/plain\n";
	echo -ne "\n";

	exit 0;
}

rm "${FILENAME}" || {
	echo -ne "Status: 500 UNEXPECTED ERROR\n";
	echo -ne "Content-type: text/plain\n";
	echo -ne "\n"
	echo -ne "500: UNEXPECTED ERROR! Cannot remove '${RESOURCE}' due to unexpected error.\n";
	echo -ne "\n";

	exit 1;
};

LOCK_FILE="/var/lock/sycamore${FILENAME}";
LOCK_DIR=$(dirname "${LOCK_FILE}");

mkdir -p "${LOCK_DIR}";

cat > /dev/null;

(
	flock -x "${FLOCK_ARGS}" 200 || exit 1;
	echo -ne "Status: 200 OK RESOURCE REMOVED\n";
	echo -ne "Content-type: text/plain\n\n";
	echo -ne "👍 ok!\n";

	cd /app && [[ -f "${UNMAKE_FILE}" ]] && rm $(cat "${UNMAKE_FILE}");

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
