#!/bin/sh -eu


###
### Globals
###
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)/.."


###
### Funcs
###
run() {
	_cmd="${1}"
	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}


###
### Checks
###

# Check Dockerfile
if [ ! -f "${CWD}/Dockerfile" ]; then
	echo "Dockerfile not found in: ${CWD}/Dockerfile."
	exit 1
fi

# Get docker Name
if ! grep -q 'image=".*"' "${CWD}/Dockerfile" > /dev/null 2>&1; then
	echo "No 'image' LABEL found"
	exit
fi

# Make sure exactly 1 container is running
NAME="$( grep 'image=".*"' "${CWD}/Dockerfile" | sed 's/^[[:space:]]*//g' | awk -F'"' '{print $2}' )"
COUNT="$( docker ps | grep -c "cytopia/${NAME}" || true)"
if [ "${COUNT}" != "1" ]; then
	echo "${COUNT} 'cytopia/${NAME}' container running. Unable to attach."
	exit 1
fi


###
### Attach
###
DID="$(docker ps | grep "cytopia/${NAME}" | awk '{print $1}')"

echo "Attaching to: cytopia/${NAME}"
run "docker exec -it ${DID} env TERM=xterm /bin/bash -l"
