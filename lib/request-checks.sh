#!/usr/bin/env bash

## Fail if the user requests a dotfile
## aka a file or a folder with a name starting with '.'
function failOnRequestDotFile
{
	grep -q '\/\.' <<< "${REQUEST_URI}" && {
		cat > /dev/null;

		echo -ne "Status: 404 RESOURCE NOT FOUND\n";
		echo -ne "Content-type: text/plain\n";
		echo -ne "\n"

		echo -ne "404: NOT FOUND! Resource '${RESOURCE}' not found.\n";
		echo -ne "\n"

		exit 1;
	}
}

## Fail and report COLLECTION NOT FOUND.
## if the given path is not a directory.
function failIfCollectionNotFound
{
	[ -d "${1}" ] || {
		cat > /dev/null;

		echo -ne "Status: 404 COLLECTION NOT FOUND\n";
		echo -ne "Content-type: text/plain\n";
		echo -ne "\n"

		echo -ne "404: NOT FOUND! Collection '${1}' does not exist.\n";
		echo -ne "\n";

		exit 1;
	}
}

## Fail and report COLLECTION EXISTS.
## if the given path is a directory.
function failIfCollecitonExists
{
	[ -d "${1}" ] && {
		cat > /dev/null;

		echo -ne "Status: 409 RESOURCE EXISTS\n";
		echo -ne "Content-type: text/plain\n";
		echo -ne "\n"

		echo -ne "409: CONFLICT! Collection already exists at '${1}'.\n";
		echo -ne "\n"

		exit 1;
	}
}

## Fail and report RESOURCE NOT FOUND.
## if the given path is not a file.
function failIfResourceNotFound
{
	[ -e "${1}" ] || {
		cat > /dev/null;

		echo -ne "Status: 404 RESOURCE NOT FOUND\n";
		echo -ne "Content-type: text/plain\n";
		echo -ne "\n"

		echo -ne "404: NOT FOUND! Resource '${1}' not found.\n";
		echo -ne "\n"

		exit 1;
	}
}

## Fail and report RESOURCE EXISTS.
## if the given path is a file.
function failIfResourceExists
{
	[ -f "${1}" ] && {
		cat > /dev/null;

		echo -ne "Status: 409 RESOURCE EXISTS\n";
		echo -ne "Content-type: text/plain\n";
		echo -ne "\n"

		echo -ne "409: CONFLICT! Resource '${1}' exists.\n";
		echo -ne "\n"

		exit 1;
	}
}

## Fail and report COLLECTION NOT EMPTY.
## if the given path is a non empty directory.
function failIfCollectionNotEmpty
{
	[ -d "${1}" ] && [ $(ls "${1}" | wc -l) -gt 0 ] && {
		cat > /dev/null;

		echo -ne "Status: 409 NOT EMPTY\n";
		echo -ne "Content-type: text/plain\n";
		echo -ne "\n"
		echo -ne "409: NOT EMPTY! Collection '${1}' is not empty.\n";
		echo -ne "\n";

		exit 1;
	}
}

