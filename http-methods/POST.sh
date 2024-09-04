#!/usr/bin/env bash
## Create record
# shellcheck source=../lib/init.sh
set -a; . "$(dirname "${0}")/../lib/init.sh"; set +a;

[[ -z "${HTTP_RSA_PUBLIC_KEY}" ]] && respondUnauthorized;
[[ -z "${HTTP_RSA_SIGNATURE}" ]] && respondUnauthorized;

failOnRequestDotFile;

CONTENT=$(cat);

verifyFingerprint "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
	|| respondUnauthorized "Fingerprint verification failed.";

verifySignature "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_SIGNATURE}" "${CONTENT}"\
	|| respondUnauthorized "Signature verification failed.";

failIfCollectionNotFound "${DIRECTORY}";
failIfResourceExists     "${FILENAME}";
# failIfCollectionNotFound "${FILENAME}";

[ -d "${FILENAME}" ] && {
	DIRECTORY=${FILENAME}
	if [ -f "${FILENAME}/.new-id.sh" ]; then {
		. ${FILENAME}/.new-id.sh;
		FILENAME=`newId`
	}
	else {
		FILENAME="${FILENAME}/"$(uuidgen)
	}
	fi
}

checkPerms "${REQUEST_METHOD}" "${FILENAME}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
	|| respondUnauthorized "Action not allowed.";

LOCK_FILE="/var/lock/snorlax_"$(sed "s#_#__#g;s#/#_#g" <<< "${FILENAME}");
LOCK_DIR=$(dirname "${LOCK_FILE}");

file "${LOCK_DIR}" >&2;
mkdir -p "${LOCK_DIR}";

(
	[ -f "${DIRECTORY}/.before-post.sh" ] && . ${DIRECTORY}/.before-post.sh;

	flock -x "${FLOCK_ARGS}" 200 || exit 1;
	echo -ne "Status: 201 OK RESOURCE CREATED\n";
	echo -ne "Content-type: text/plain\n";
	echo -ne "Location: ${FILENAME##${PUBLIC_ROOT}}\n";
	echo -ne "\n"

	tee "${FILENAME}" <<< "${CONTENT}";

	[ -f "${DIRECTORY}/.after-post.sh" ] && . ${DIRECTORY}/.after-post.sh

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
