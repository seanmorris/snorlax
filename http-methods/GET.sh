#!/usr/bin/env bash
## Serve record
# shellcheck source=../lib/init.sh
set -a; . "$(dirname "${0}")/../lib/init.sh"; set +a;

[[ -z "${HTTP_RSA_PUBLIC_KEY:-}" ]] && respondUnauthorized;
[[ -z "${HTTP_RSA_SIGNATURE:-}" ]] && respondUnauthorized;

CONTENT=$(cat);

failOnRequestDotFile;

verifySignature "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_SIGNATURE}" "${CONTENT}"\
	|| respondUnauthorized "Signature verification failed.";

verifyFingerprint "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_SIGNATURE}" "${CONTENT}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
	|| respondUnauthorized "Fingerprint verification failed.";

failIfCollectionNotFound "${DIRECTORY}";
failIfResourceNotFound   "${FILENAME}";

checkPerms "${REQUEST_METHOD}" "${FILENAME}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
	|| respondUnauthorized "Action not allowed.";

LOCK_FILE="/var/lock/sycamore${FILENAME}";
LOCK_DIR=$(dirname "${LOCK_FILE}");

mkdir -p "${LOCK_DIR}";

(
	if [[ "${HTTP_ACCEPT}" == "text/plain-stream" ]]; then {
		echo -ne "Status: 200 OK\n";
		echo -ne "Content-type: text/plain\n";
		echo -ne "Transfer-Encoding: chunked\n";
		echo -ne "\n";

		chunkFileDescriptor <(cat "${FILENAME}");

		if [[ ${EVENT_WAIT} -eq -1 ]]; then {
			chunkFileDescriptor <(tail -n 0 -f "${FILENAME}");
		}
		else {
			chunkFileDescriptor <(timeout ${TIMEOUT_ARGS} tail -n 0 -f "${FILENAME}");
		}
		fi

		echo -ne "0\r\n\r\n";
	}
	else {
		flock -s "${FLOCK_ARGS}" 200 || exit 1;
		echo -ne "Status: 200 OK\n";
		echo -ne "Content-type: text/plain\n";
		echo -ne "\n";

		cat "${FILENAME}";
	}
	fi

	true;

) 200> "${LOCK_FILE}" || {
	echo -ne "Status: 409 RESOURCE ACTIVE\n";
	echo -ne "Content-type: text/plain\n";
	echo -ne "Retry-After: 1\n";
	echo -ne "\n";
	echo -ne "409: ACTIVE! Resource is currently being modified by another user.\n";
	echo -ne "Please wait and try again.\n";
	echo -ne "\n";
};
