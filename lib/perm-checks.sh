#!/usr/bin/env bash

function checkPerms
{
	local METHOD=$1;
	local DIRECTORY=$(dirname "${2}");
	local PERM_FILE="${DIRECTORY}/.PERMS";

	[[ -f ${PERM_FILE} ]] || {
		cat > /dev/null;

		echo -ne "Status: 500 UNEXPECTED ERROR\n";
		echo -ne "Content-type: text/plain\n";
		echo -ne "\n"

		echo -ne "500: UNEXPECTED ERROR!\n";
		echo -ne "\n";

		exit 1;
	};

	local LINE;
	local ALLOWED;

	while read -r LINE; do {

		local METHODS=$(cut -d' ' -f 2- <<< "${LINE}");

		for ALLOWED in ${METHODS}; do {

			[[ "${METHOD}" == "${ALLOWED}" ]] && {
				return 0;
			}

		}; done;

	}; done < "${PERM_FILE}";

	return 1;
}
