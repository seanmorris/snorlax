#!/usr/bin/env bash
# set -a; . lib/init.sh; set +a;
set -a; . lib/crypto.sh; set +a;

function request
{
	METHOD=${1:-GET};
	LOCATION=${2:-};
	FILENAME=${3:-/dev/null};
	STREAM=${4:-};
	MESSAGE=

	# [[ ${METHOD} == 'DELETE' ]] && {
	# 	FILENAME=$(localTmp);
	# 	echo "delete-token" > ${FILENAME};
	# }

	[[ -z ${FILENAME} ]] || {
		MESSAGE=$(cat ${FILENAME});
	}

	ACCEPT_ENCODING='*';

	[[ -z ${STREAM} ]] || {
		ACCEPT_ENCODING='chunked';
	}

	SIGNATURE=$(\
		echo '-----BEGIN RSA SIGNATURE-----';\
		openssl dgst -sha1 -sign ssh/private-key.pem <(echo "${MESSAGE}") | openssl base64
		echo '-----END RSA SIGNATURE-----';\
	);

	FINGERPRINT=$(fingerprintKey ssh/public-key.pem);

	PUBLIC_KEY=$(cat ssh/public-key.pem);

	[[ -z ${MESSAGE:-} ]] && {
		curl -i --http2\
			-X "${METHOD}" $LOCATION\
			-H "accept-encoding: ${ACCEPT_ENCODING}"\
			-H "rsa-public-key-fingerprint: ${FINGERPRINT}"\
			-H "rsa-public-key: ${PUBLIC_KEY//$'\n'/'\n'}"\
			-H "rsa-signature: ${SIGNATURE//$'\n'/'\n'}"\
			--data-binary @<(echo "${MESSAGE}")
	} || {
		curl -i --http2\
			-X "${METHOD}" $LOCATION\
			-H "accept-encoding: ${ACCEPT_ENCODING}"\
			-H "rsa-public-key-fingerprint: ${FINGERPRINT}"\
			-H "rsa-public-key: ${PUBLIC_KEY//$'\n'/'\n'}"\
			-H "rsa-signature: ${SIGNATURE//$'\n'/'\n'}"\
			--data-binary @<(echo "${MESSAGE}")
	}

	# [[ ${METHOD} == 'DELETE' ]] && {
	# 	rm -rf $(dirname $(localTmp));
	# }
}

