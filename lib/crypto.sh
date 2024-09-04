#!/usr/bin/env bash

## Get a fingerprint for a given public key.
function fingerprintKey
{
	openssl pkey -pubin -in "${1}" -inform PEM -outform DER \
		| openssl dgst -sha1 \
		| cut -d' ' -f 2;
}

## Verify that the given message matches its signature
## and that they both match a given public key.
function verifySignature
{
	local PUBLIC_KEY=${1};
	local SIGNATURE=${2};
	local CONTENT=${3};

	openssl dgst -sha1\
		-verify <(printf '%b\n' "${PUBLIC_KEY}")\
		-signature <(printf '%b\n' "${SIGNATURE}"\
			| tail -c +31\
			| head -c -28\
			| base64 -d\
		) <<< "${CONTENT}" \
	1>/dev/null \
	2>/dev/null;
}

## Verify that the given fingerprint matches the given
## public key and that they both match the public key on
## file under that fingerprint.
function verifyFingerprint
{
	local PUBLIC_KEY=${1};
	local PROVIDED_PRINT=${2};

	KEY_FILE="/app/allowed-keys/${PROVIDED_PRINT}.pem";

	[[ -f ${KEY_FILE} ]] || {
		return 1;
	}

	CALCULATED_PRINT=$(fingerprintKey <(printf '%b\n' "${PUBLIC_KEY}"));

	[ "${CALCULATED_PRINT}" == "${PROVIDED_PRINT}" ] | {
		return 1;
	}

	cmp "${KEY_FILE}" <( printf '%b\n' "${PUBLIC_KEY}" );
}
