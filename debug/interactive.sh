	#!/usr/bin/env bash
	# set -eu;
	# set -x;

	HOST=localhost:8888

	function mainmenu
	{
		HEIGHT=7
		WIDTH=40
		CHOICE_HEIGHT=0
		BACKTITLE="Snorlax Interactive Debugger"
		TITLE='\Z0Snorlax Interactive Debugger\Z0'
		MENU="Main Menu"
		OPTIONS=(
			r "Request"
			s "Settings"
			q "quit"
		)

		CHOICE=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
			"${OPTIONS[@]}" \
		2>&1 >/dev/tty)

		case $CHOICE in
			q) clear; exit;
				;;
			r) request;
				;;
			s) settings;
				;;
		esac;
	}

	function request
	{
		HEIGHT=8
		WIDTH=40
		CHOICE_HEIGHT=0
		BACKTITLE="Snorlax Interactive Debugger"
		TITLE='\Z0Snorlax Interactive Debugger\Z0'
		MENU="What kind of request would you like to make?"
		OPTIONS=(
			g "GET"
			e "GET (events)"
			c "GET (chunks)"
			ol "POST (line)"
			al "PATCH (line)"
			ul "PUT (line)"
			of "POST (file)"
			af "PATCH (file)"
			uf "PUT (file)"
			d "DELETE"
			b "back"
		)

		CHOICE=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
			"${OPTIONS[@]}" \
		2>&1 >/dev/tty)

		case ${CHOICE} in
			g) request_GET;
				;;
			e) request_GETEVENTS;
				;;
			c) request_GETCHUNKS;
				;;
			ol) request_POST_LINE;
				;;
			al) request_PATCH_LINE;
				;;
			ul) request_PUT_LINE;
				;;
			of) request_POST_FILE;
				;;
			af) request_PATCH_FILE;
				;;
			uf) request_PUT_FILE;
				;;
			d) request_DELETE;
				;;

		esac;
	}

	function request_GET
	{
		HEIGHT=15
		WIDTH=40
		TITLE="\Z0${HOST}:\Z0"
		BACKTITLE="Snorlax Interactive Debugger"

		REQUEST_PATH=${REQUEST_PATH:-/}

		REQUEST_PATH=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Path:" "$HEIGHT" "$WIDTH" "${REQUEST_PATH}" \
		2>&1 >/dev/tty)

		HEIGHT=35
		WIDTH=60
		TITLE="\Z0${REQUEST_PATH}\Z0"

		debug/get.sh ${HOST}${REQUEST_PATH} 2>/dev/null | dos2unix > /tmp/snorlax-result

		dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--textbox /tmp/snorlax-result $HEIGHT $WIDTH
	}

	function request_GETEVENTS
	{
		HEIGHT=15
		WIDTH=40
		TITLE="\Z0${HOST}:\Z0"
		BACKTITLE="Snorlax Interactive Debugger"

		REQUEST_PATH=${REQUEST_PATH:-/}

		REQUEST_PATH=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Path:" "$HEIGHT" "$WIDTH" "${REQUEST_PATH}" \
		2>&1 >/dev/tty)

		HEIGHT=35
		WIDTH=60
		TITLE="\Z0Events: ${REQUEST_PATH}\Z0"

		dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--prgbox "Events: ${REQUEST_PATH}" "debug/stream.sh ${HOST}${REQUEST_PATH} 2>/dev/null" $HEIGHT $WIDTH
	}

	function request_GETCHUNKS
	{
		HEIGHT=15
		WIDTH=40
		TITLE="\Z0${HOST}:\Z0"
		BACKTITLE="Snorlax Interactive Debugger"

		REQUEST_PATH=${REQUEST_PATH:-/}

		REQUEST_PATH=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Path:" "$HEIGHT" "$WIDTH" "${REQUEST_PATH}" \
		2>&1 >/dev/tty)

		HEIGHT=35
		WIDTH=60

		dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--prgbox "Chunks: ${REQUEST_PATH}" "debug/chunks.sh ${HOST}${REQUEST_PATH} 2>/dev/null" $HEIGHT $WIDTH
	}

	function request_POST_LINE
	{
		HEIGHT=15
		WIDTH=40
		BACKTITLE="Snorlax Interactive Debugger"
		TITLE="\Z0${HOST}:\Z0"

		REQUEST_PATH=${REQUEST_PATH:-/}
		REQUEST_FILENAME=${REQUEST_FILENAME:-~/}

		REQUEST_PATH=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Path:" "$HEIGHT" "$WIDTH" "${REQUEST_PATH}" \
		2>&1 >/dev/tty)

		HEIGHT=25
		WIDTH=60
		REQUEST_DATA=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Data:" $HEIGHT $WIDTH "${REQUEST_DATA}" \
		2>&1 >/dev/tty)

		echo "${REQUEST_DATA}" > /tmp/snorlax-request;

		HEIGHT=35
		WIDTH=60
		TITLE="\Z0${REQUEST_PATH}\Z0"

		debug/post.sh "${HOST}${REQUEST_PATH}" /tmp/snorlax-request 2>/dev/null | dos2unix > /tmp/snorlax-result

		HEIGHT=45
		WIDTH=80
		TITLE="\Z0RESPONSE:\Z0"

		dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--textbox /tmp/snorlax-result $HEIGHT $WIDTH \
		2>&1 >/dev/tty
	}

	function request_PATCH_LINE
	{
		HEIGHT=15
		WIDTH=40
		BACKTITLE="Snorlax Interactive Debugger"
		TITLE="\Z0${HOST}:\Z0"

		REQUEST_PATH=${REQUEST_PATH:-/}
		REQUEST_FILENAME=${REQUEST_FILENAME:-~/}

		REQUEST_PATH=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Path:" "$HEIGHT" "$WIDTH" "${REQUEST_PATH}" \
		2>&1 >/dev/tty)

		HEIGHT=25
		WIDTH=60
		REQUEST_DATA=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Data:" "$HEIGHT" "$WIDTH" "${REQUEST_DATA}" \
		2>&1 >/dev/tty)

		echo "${REQUEST_DATA}" > /tmp/snorlax-request;

		HEIGHT=35
		WIDTH=60
		TITLE='\Z0Response:\Z0'

		debug/patch.sh "${HOST}${REQUEST_PATH}" /tmp/snorlax-request 2>/dev/null | dos2unix > /tmp/snorlax-result

		HEIGHT=45
		WIDTH=80
		TITLE="\Z0${REQUEST_PATH}\Z0"

		dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--textbox /tmp/snorlax-result $HEIGHT $WIDTH \
		2>&1 >/dev/tty
	}

	function request_PUT_LINE
	{
		HEIGHT=15
		WIDTH=40
		BACKTITLE="Snorlax Interactive Debugger"
		TITLE="\Z0${HOST}:\Z0"

		REQUEST_PATH=${REQUEST_PATH:-/}
		REQUEST_FILENAME=${REQUEST_FILENAME:-~/}

		REQUEST_PATH=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Path:" "$HEIGHT" "$WIDTH" "${REQUEST_PATH}" \
		2>&1 >/dev/tty)

		HEIGHT=25
		WIDTH=60
		REQUEST_DATA=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Data:" "$HEIGHT" "$WIDTH" "${REQUEST_DATA}" \
		2>&1 >/dev/tty)

		echo "${REQUEST_DATA}" > /tmp/snorlax-request;

		HEIGHT=35
		WIDTH=60
		TITLE="\Z0${REQUEST_PATH}\Z0"

		debug/put.sh "${HOST}${REQUEST_PATH}" /tmp/snorlax-request 2>/dev/null | dos2unix > /tmp/snorlax-result

		HEIGHT=45
		WIDTH=80
		TITLE="\Z0RESPONSE:\Z0"

		dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--textbox /tmp/snorlax-result $HEIGHT $WIDTH \
		2>&1 >/dev/tty
	}
	function request_POST_FILE
	{
		HEIGHT=15
		WIDTH=40
		BACKTITLE="Snorlax Interactive Debugger"
		TITLE="\Z0${HOST}:\Z0"

		REQUEST_PATH=${REQUEST_PATH:-/}
		REQUEST_FILENAME=${REQUEST_FILENAME:-~/}

		REQUEST_PATH=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Path:" "$HEIGHT" "$WIDTH" "${REQUEST_PATH}" \
		2>&1 >/dev/tty)

		HEIGHT=25
		WIDTH=60
		REQUEST_FILENAME=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--fselect ${REQUEST_FILENAME} $HEIGHT $WIDTH \
		2>&1 >/dev/tty)

		HEIGHT=35
		WIDTH=60
		TITLE="\Z0${REQUEST_PATH}\Z0"

		debug/post.sh "${HOST}${REQUEST_PATH}" "${REQUEST_FILENAME}" 2>/dev/null | dos2unix > /tmp/snorlax-result

		HEIGHT=45
		WIDTH=80
		TITLE="\Z0RESPONSE:\Z0"

		dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--textbox /tmp/snorlax-result $HEIGHT $WIDTH \
		2>&1 >/dev/tty
	}

	function request_PATCH_FILE
	{
		HEIGHT=15
		WIDTH=40
		BACKTITLE="Snorlax Interactive Debugger"
		TITLE="\Z0${HOST}:\Z0"

		REQUEST_PATH=${REQUEST_PATH:-/}
		REQUEST_FILENAME=${REQUEST_FILENAME:-~/}

		REQUEST_PATH=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Path:" "$HEIGHT" "$WIDTH" "${REQUEST_PATH}" \
		2>&1 >/dev/tty)

		HEIGHT=25
		WIDTH=60

		REQUEST_FILENAME=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--fselect ${REQUEST_FILENAME} $HEIGHT $WIDTH \
		2>&1 >/dev/tty)

		HEIGHT=35
		WIDTH=60
		TITLE='\Z0Response:\Z0'

		debug/patch.sh "${HOST}${REQUEST_PATH}" "${REQUEST_FILENAME}" 2>/dev/null | dos2unix > /tmp/snorlax-result

		HEIGHT=45
		WIDTH=80
		TITLE="\Z0${REQUEST_PATH}\Z0"

		dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--textbox /tmp/snorlax-result $HEIGHT $WIDTH \
		2>&1 >/dev/tty
	}

	function request_PUT_FILE
	{
		HEIGHT=15
		WIDTH=40
		BACKTITLE="Snorlax Interactive Debugger"
		TITLE="\Z0${HOST}:\Z0"

		REQUEST_PATH=${REQUEST_PATH:-/}
		REQUEST_FILENAME=${REQUEST_FILENAME:-~/}

		REQUEST_PATH=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Path:" "$HEIGHT" "$WIDTH" "${REQUEST_PATH}" \
		2>&1 >/dev/tty)

		HEIGHT=25
		WIDTH=60
		REQUEST_FILENAME=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--fselect ${REQUEST_FILENAME} $HEIGHT $WIDTH \
		2>&1 >/dev/tty)

		HEIGHT=35
		WIDTH=60
		TITLE="\Z0${REQUEST_PATH}\Z0"

		debug/put.sh "${HOST}${REQUEST_PATH}" "${REQUEST_FILENAME}" 2>/dev/null | dos2unix > /tmp/snorlax-result

		HEIGHT=45
		WIDTH=80
		TITLE="\Z0RESPONSE:\Z0"

		dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--textbox /tmp/snorlax-result $HEIGHT $WIDTH \
		2>&1 >/dev/tty
	}

	function request_DELETE
	{
		HEIGHT=15
		WIDTH=40
		BACKTITLE="Snorlax Interactive Debugger"
		TITLE="\Z0${HOST}:\Z0"

		REQUEST_PATH=${REQUEST_PATH:-/}
		REQUEST_FILENAME=${REQUEST_FILENAME:-~/}

		REQUEST_PATH=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Path:" "$HEIGHT" "$WIDTH" "${REQUEST_PATH}" \
		2>&1 >/dev/tty)

		HEIGHT=25
		WIDTH=60

		debug/delete.sh "${HOST}${REQUEST_PATH}" 2>/dev/null | dos2unix > /tmp/snorlax-result

		HEIGHT=15
		WIDTH=40
		TITLE="\Z0${REQUEST_PATH}\Z0"

		dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--textbox /tmp/snorlax-result $HEIGHT $WIDTH \
		2>&1 >/dev/tty
	}

	function settings
	{
		HEIGHT=15
		WIDTH=40
		CHOICE_HEIGHT=0
		BACKTITLE="Snorlax Interactive Debugger"
		TITLE='\Z0Snorlax Interactive Debugger\Z0'
		MENU="Main Menu"
		OPTIONS=(
			h "Server Host Name"
			g "Generate Encryption Key"
			b "back"
		)

		CHOICE=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
			"${OPTIONS[@]}" \
		2>&1 >/dev/tty)

		case $CHOICE in
			g) settings_changeHost;
				;;
			h) settings_generateKey;
				;;
		esac;
	}

	function settings_changeHost
	{
		HEIGHT=15
		WIDTH=40
		BACKTITLE="Snorlax Interactive Debugger"
		TITLE='\Z0Snorlax Interactive Debugger\Z0'
		MENU="Main Menu"

		HOST=$(dialog --clear --colors \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--inputbox "Hostname:" $HEIGHT $WIDTH ${HOST} \
		2>&1 >/dev/tty)
	}

	function settings_generateKey
	{
		echo "";
	}

	while(true); do {
		mainmenu;
	}; done;

