#!/usr/bin/env bash

## Fail and report NOT AUTHORIZED.
function respondUnauthorized
{
	cat > /dev/null;

	echo -ne "Status: 401 NOT AUTHORIZED\n";
	echo -ne "Content-type: text/plain\n\n";
	echo -ne "401: NOT AUTHORIZED! ${1:-}";
	echo -ne "\n"

	[[ -z ${2:-} ]] || {
		echo -ne "${2:-}";
		echo -ne "\n"
	}

	exit 1;
}

## Fail and report NOT FOUND.
function respondNotFound
{
	cat > /dev/null;

	echo -ne "Status: 404 NOT FOUND\n";
	echo -ne "Content-type: text/plain\n\n";
	echo -ne "404: NOT FOUND! ${1:-}";
	echo -ne "\n"

	[[ -z ${2:-} ]] || {
		echo -ne "${2:-}";
		echo -ne "\n"
	}

	exit 1;
}

function chunkFileDescriptor
{
	cat "${1}" | while read LINE; do {
		printf '%x\r\n' $(echo -ne "${LINE}\n" | wc -c);
		echo -ne "${LINE}\n\r\n";
	}; done;
}

function respondChallengeString
{
	cat > /dev/null;

	RANDOM_BYTES=$(openssl rand 16 | openssl base64);
	# RANDOM_BYTES='yo yo';
	SYMMETRIC_KEY=$(openssl rand 32 | openssl base64);

	echo -ne "Status: 200 OK\n";
	echo -ne "Content-type: text/plain\n";
	echo -ne "\n";
	echo -ne "# GENERATED=$(date +%s) \n";
	echo -ne "\n";
	
	echo -ne "-----BEGIN PLAINTEXT CHALLENGE----- \n";
	echo "${RANDOM_BYTES}";
	echo -ne "-----END PLAINTEXT CHALLENGE-----\n";
	echo -ne "\n";

	exit 0;

	echo -ne "-----BEGIN PLAINTEXT SYMMETRIC KEY----- \n";
	echo -ne "${SYMMETRIC_KEY}\n";
	echo -ne "-----END PLAINTEXT SYMMETRIC KEY-----\n";
	echo -ne "\n";
	
	RANDOM_ENCRYPTED=$(openssl enc -aes-256-cbc -salt -in <(echo "${RANDOM_BYTES}") -k <(echo "${SYMMETRIC_KEY}") | openssl base64)

	echo -ne '-----BEGIN ENCRYPTED CHALLENGE-----\n';
	echo "${RANDOM_ENCRYPTED}";
	echo -ne '-----END ENCRYPTED CHALLENGE-----\n';
	echo -ne '\n';

	# echo -ne '-----BEGIN DECRYPTED CHALLENGE-----\n';
	# openssl enc -d -aes-256-cbc -d -salt -in <(echo "${RANDOM_ENCRYPTED}" | openssl base64 -d) -k <(echo "${SYMMETRIC_KEY}")
	# echo -ne '-----END DECRYPTED CHALLENGE-----\n';
	# echo -ne '\n';

	# USER_PUBLIC_KEY=/app/allowed-hosts/1c147053ba4e81d6a939fb2654bcd95318efb4c3.pem
	USER_PUBLIC_KEY=/app/ssh/public-key.pem
	
	SYMMETRIC_ENCRYPTED=$(openssl rsautl -encrypt -inkey "${USER_PUBLIC_KEY}" -pubin -in <(echo "${SYMMETRIC_KEY}") | openssl base64)

	echo -ne '-----BEGIN ENCRYPTED SYMMETRIC KEY-----\n';
	echo -ne "${SYMMETRIC_ENCRYPTED}\n";
	echo -ne '-----END ENCRYPTED SYMMETRIC KEY-----\n';
	echo -ne '\n';
	
	USER_PRIVATE_KEY=/app/ssh/private-key.pem
	
	SYMMETRIC_DECRYPTED=$(openssl rsautl -decrypt -inkey "${USER_PRIVATE_KEY}" -in <(echo "${SYMMETRIC_ENCRYPTED}" | openssl base64 -d) | openssl base64)

	echo -ne '-----BEGIN DECRYPTED SYMMETRIC KEY-----\n';
	echo -ne "${SYMMETRIC_DECRYPTED}\n"
	echo -ne '-----END DECRYPTED SYMMETRIC KEY-----\n';
	echo -ne '\n';

	echo -ne '-----BEGIN DECRYPTED CHALLENGE-----\n';
	openssl enc -d -aes-256-cbc -d -salt -in <(echo "${RANDOM_ENCRYPTED}" | openssl base64 -d) -k <(echo "${SYMMETRIC_KEY}")
	echo -ne '-----END DECRYPTED CHALLENGE-----\n';
	echo -ne '\n';
	
	# echo -ne '-----BEGIN RSA SIGNATURE-----\n';
	# openssl dgst -sha1 -sign /app/ssh/private-key.pem <(echo "${RANDOM_BYTES}") | openssl base64
	# echo -ne '-----END RSA SIGNATURE-----\n';
	# echo -ne '\n';

	exit 0;
}