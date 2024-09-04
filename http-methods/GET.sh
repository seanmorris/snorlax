#!/usr/bin/env bash
## Serve record
# shellcheck source=../lib/init.sh
set -a; . "$(dirname "${0}")/../lib/init.sh"; set +a;

if [[ -z "${HTTP_RSA_PUBLIC_KEY:-}" ]] && [[ -z "${HTTP_RSA_SIGNATURE:-}" ]]; then {
	HTTP_RSA_PUBLIC_KEY_FINGERPRINT="ANON"
}
fi

# [[ -z "${HTTP_RSA_PUBLIC_KEY:-}" ]] && respondUnauthorized;
# [[ -z "${HTTP_RSA_SIGNATURE:-}" ]] && respondUnauthorized;

CONTENT=$(cat);

failOnRequestDotFile;

if [ "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}" != "ANON" ]; then {
	verifyFingerprint "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
		|| respondUnauthorized "Fingerprint verification failed.";

	verifySignature "${HTTP_RSA_PUBLIC_KEY}" "${HTTP_RSA_SIGNATURE}" "${CONTENT}"\
		|| respondUnauthorized "Signature verification failed.";
}
fi

failIfCollectionNotFound "${DIRECTORY}";
failIfResourceNotFound   "${FILENAME}";

checkPerms "${REQUEST_METHOD}" "${FILENAME}" "${HTTP_RSA_PUBLIC_KEY_FINGERPRINT}"\
	|| respondUnauthorized "Action not allowed.";

[ -d "${FILENAME}" ] && {
	if [ "${HTTP_ACCEPT}" == "text/event-stream" ]; then {
		echo -ne "Status: 200 OK\n";
		echo -ne "X-Accel-Buffering: no\n";
		echo -ne "Content-type: text/event-stream\n";
		echo -ne "Cache-control: no-cache\n";
		echo -ne "\n";

		INOTIFY_OPTIONS="-m ${FILENAME} -e modify -e create -e delete --timefmt %s.%N"

		# trap "echo CONNECTION CLOSED >&2; exit 0;" EXIT

		if [[ ${EVENT_WAIT} -eq -1 ]]; then {
			inotifywait ${INOTIFY_OPTIONS} --format "id:%T%nevent:%e%ndata:${REQUEST_PATH}/%f%n"
		}
		else {
			inotifywait ${INOTIFY_OPTIONS} --format "id:%T%nevent:%e%ndata:${REQUEST_PATH}/%f%n" -t "${EVENT_WAIT}";
		}
		fi
	}
	elif [ "${HTTP_ACCEPT}" == "text/stream" ]; then {
		echo -ne "Status: 200 OK\n";
		echo -ne "X-Accel-Buffering: no\n";
		echo -ne "Transfer-encoding: chunked\n";
		echo -ne "Content-type: text/plain\n";
		echo -ne "Cache-control: no-cache\n";
		echo -ne "\n";

		INOTIFY_OPTIONS="-m ${FILENAME} -e modify -e create -e delete"

		if [[ ${EVENT_WAIT} -eq -1 ]]; then {
			inotifywait ${INOTIFY_OPTIONS} --format "%e:${REQUEST_PATH}/%f"
		}
		else {
			inotifywait ${INOTIFY_OPTIONS} --format "%e:${REQUEST_PATH}/%f" -t ${EVENT_WAIT};
		}
		fi
	}
	else {
		[ -f "${DIRECTORY}/.before-get.sh" ] && . ${DIRECTORY}/.before-get.sh

		echo -ne "Status: 200 OK\n";
		# echo -ne "Content-type: inode/directory\n";
		echo -ne "Content-type: text/plain\n";
		echo -ne "\n";

		if [ -f "${FILENAME}/.index.sh" ]; then {
			. ${FILENAME}/.index.sh;
		}
		else {
			PAGE=${QUERY_PARAMS[p]:-0};
			sort=${QUERY_PARAMS[s]:-creation};
			ls -t --time=${sort} ${FILENAME} | tail +$((5 * ${PAGE})) | head -n 10
		}
		fi

		[ -f "${DIRECTORY}/.after-get.sh" ] && . ${DIRECTORY}/.after-get.sh
	}
	fi

	exit 0;
}

LOCK_FILE="/var/lock/snorlax_"$(sed "s#_#__#g;s#/#_#g" <<< "${FILENAME}");
LOCK_DIR=$(dirname "${LOCK_FILE}");

mkdir -p "${LOCK_DIR}";

(
	if [ "${HTTP_ACCEPT}" == "text/event-stream" ]; then {
		echo -ne "Status: 200 OK\n";
		echo -ne "X-Accel-Buffering: no\n";
		echo -ne "Content-type: text/event-stream\n";
		echo -ne "Cache-control: no-cache\n";
		echo -ne "\n";

		if [ "${HTTP_LAST_EVENT_ID}" == "earliest" ]; then {
			eventsFromFileDescriptor line <(cat "${FILENAME}");
		}
		fi

		if [[ ${EVENT_WAIT} -eq -1 ]]; then {
			eventsFromFileDescriptor line <(tail -n 0 -f "${FILENAME}");
		}
		else {
			eventsFromFileDescriptor line <(timeout ${TIMEOUT_ARGS} tail -n 0 -f "${FILENAME}");
		}
		fi
	}
	elif [ "${HTTP_ACCEPT}" == "text/stream" ]; then {
		echo -ne "Status: 200 OK\n";
		echo -ne "X-Accel-Buffering: no";
		echo -ne "Content-type: text/plain\n";
		echo -ne "Cache-control: no-cache\n";
		echo -ne "\n";

		if [ "${HTTP_LAST_EVENT_ID}" == "earliest" ]; then {
			cat "${FILENAME}";
		}
		fi

		if [[ ${EVENT_WAIT} -eq -1 ]]; then {
			tail -n 0 -f "${FILENAME}";
		}
		else {
			timeout ${TIMEOUT_ARGS} tail -n 0 -f "${FILENAME}";
		}
		fi
	}
	else {

		flock -s "${FLOCK_ARGS}" 200 || exit 1;

		CONTENT_TYPE=$(file --brief --mime-type ${FILENAME});

		[ -f "${DIRECTORY}/.before-get.sh" ] && . ${DIRECTORY}/.before-get.sh
		echo -ne "Status: 200 OK\n";
		echo -ne "Content-type: ${CONTENT_TYPE}\n";
		echo -ne "\n";

		# touch -a "${FILENAME}";
		cat < "${FILENAME}";

		[ -f "${DIRECTORY}/.after-get.sh" ] && . ${DIRECTORY}/.after-get.sh
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
