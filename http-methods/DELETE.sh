#!/usr/bin/env bash
## Delete record
# shellcheck source=../lib/init.sh
set -a; . "$(dirname "${0}")/../lib/init.sh"; set +a;

[[ -z "${HTTP_RSA_PUBLIC_KEY}" ]] && respondUnauthorized;
[[ -z "${HTTP_RSA_SIGNATURE}" ]] && respondUnauthorized;

failOnRequestDotFile;

CONTENT="$(cat)";

verifyFingerprint "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
	|| respondUnauthorized "Fingerprint verification failed.";

verifySignature "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_SIGNATURE}" "${CONTENT}"\
	|| respondUnauthorized "Signature verification failed.";

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

LOCK_FILE="/var/lock/snorlax_"$(sed "s#_#__#g;s#/#_#g" <<< "${FILENAME}");
LOCK_DIR=$(dirname "${LOCK_FILE}");

mkdir -p "${LOCK_DIR}";

cat > /dev/null;

(
	[ -f "${DIRECTORY}/.before-delete.sh" ] && . ${DIRECTORY}/.before-delete.sh

	flock -x "${FLOCK_ARGS}" 200 || exit 1;

	rm "${FILENAME}" || {
		echo -ne "Status: 500 UNEXPECTED ERROR\n";
		echo -ne "Content-type: text/plain\n";
		echo -ne "\n"
		echo -ne "500: UNEXPECTED ERROR! Cannot remove '${RESOURCE}' due to unexpected error.\n";
		echo -ne "\n";

		exit 1;
	};

	echo -ne "Status: 200 OK RESOURCE REMOVED\n";
	echo -ne "Content-type: text/plain\n\n";
	echo -ne "👍 ok!\n";

	# cd /app && [[ -f "${UNMAKE_FILE}" ]] && rm $(cat "${UNMAKE_FILE}");

	[ -f "${DIRECTORY}/.after-delete.sh" ] && . ${DIRECTORY}/.after-delete.sh

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
