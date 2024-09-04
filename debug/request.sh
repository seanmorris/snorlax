#!/usr/bin/env bash
# set -a; . lib/init.sh; set +a;
set -a; . lib/crypto.sh; set +a;

function request
{
	METHOD=${1:-GET};
	LOCATION=${2:-};
	FILENAME=${3:-/dev/null};
	ACCEPT=${4:-};
	MESSAGE=

	[[ -z ${FILENAME} ]] || {
		MESSAGE=$(cat ${FILENAME});
	}

	SIGNATURE=$(\
		echo '-----BEGIN RSA SIGNATURE-----';\
		openssl dgst -sha1 -sign ssh/private-key.pem <(echo "${MESSAGE}") | openssl base64
		echo '-----END RSA SIGNATURE-----';\
	);

	FINGERPRINT=$(fingerprintKey ssh/public-key.pem);

	PUBLIC_KEY=$(cat ssh/public-key.pem);

	curl -sND /dev/stderr --http2 --no-keepalive \
		-X "${METHOD}" "$LOCATION" \
		-H "accept: ${ACCEPT}" \
		-H "Last-Event-ID: earliest" \
		-H "rsa-public-key-fingerprint: ${FINGERPRINT}" \
		-H "rsa-public-key: ${PUBLIC_KEY//$'\n'/'\n'}" \
		-H "rsa-signature: ${SIGNATURE//$'\n'/'\n'}" \
		--data-binary @<(echo "${MESSAGE}") &
	CURL_PID=$!
	trap "kill ${CURL_PID}; exit 0;" EXIT
	wait;

	trap "exit 0;" EXIT
}
