#!/usr/bin/env bash

function checkPerms
{
	local CHECK="$1";
	local RESOURCE="$2";
	local DIRECTORY="$(dirname "${RESOURCE}")/";
	local PRINT="$3";

	local ROLES="${PRINT}";

	if [ -f "/app/roles/${PRINT}" ]; then
		ROLES="${PRINT} "$(cat "/app/roles/${PRINT}")
	fi;

	if [ -d "${RESOURCE}" ]; then {
		RESOURCE="${RESOURCE}/";
		DIRECTORY="${RESOURCE}";
	} fi;

	local PERM_FILE="${DIRECTORY}.PERMS";

	while [ "${DIRECTORY}" != ${PUBLIC_ROOT} ]; do {
		if [ -f "${PERM_FILE}" ]; then {
			break;
		} fi;
		if [ ! -f "${PERM_FILE}" ]; then {
			DIRECTORY=`dirname ${DIRECTORY}`/;
			PERM_FILE="${DIRECTORY}/.PERMS";
			break;
		} fi;
	}; done;

	local CHECK_PATH="${RESOURCE##${DIRECTORY}}"

	[ -f "${PERM_FILE}" ] || respondUnauthorized "No permissions granted.";

	local LINE;
	local ALLOWED;

	while read -r LINE; do {

		if [[ $LINE == "#*" ]] || [[ $LINE == "" ]]; then {
			continue;
		} fi;

		local PATTERN="$(cut -d' ' -f1 <<< "${LINE}")";
		local ROLE="$(cut -d' ' -f2 <<< "${LINE}")";

		[[ $CHECK_PATH =~ $PATTERN ]] || continue;
		fgrep -q "$ROLE" <<< "$ROLES" || continue;
		local PERMS=$(cut -d' ' -f3- <<< "${LINE}");
		fgrep -q "$CHECK" <<< "$PERMS" || continue;

		return 0;

	}; done < "${PERM_FILE}";

	return 1;
}
