#!/bin/sh

set -e
set -u

run() {
	cmd="${1}"
	to_stderr=0

	# Output to stderr instead?
	if [ "${#}" -eq "2" ]; then
		to_stderr="${2}"
	fi

	red="\033[0;31m"
	green="\033[0;32m"
	yellow="\033[0;33m"
	reset="\033[0m"

	if [ "${to_stderr}" -eq "0" ]; then
		printf "${yellow}[%s] ${red}%s \$ ${green}${cmd}${reset}\n" "$(hostname)" "$(whoami)"
	else
		printf "${yellow}[%s] ${red}%s \$ ${green}${cmd}${reset}\n" "$(hostname)" "$(whoami)" >&2
	fi

	if sh -c "LANG=C LC_ALL=C ${cmd}"; then
		if [ "${to_stderr}" -eq "0" ]; then
			printf "${green}[%s]${reset}\n" "OK"
		else
			printf "${green}[%s]${reset}\n" "OK" >&2
		fi
		return 0
	else
		if [ "${to_stderr}" -eq "0" ]; then
			printf "${red}[%s]${reset}\n" "NO"
		else
			printf "${red}[%s]${reset}\n" "NO" >&2
		fi
		return 1
	fi
}

run_fail() {
	cmd="${1}"
	to_stderr=0

	# Output to stderr instead?
	if [ "${#}" -eq "2" ]; then
		to_stderr="${2}"
	fi

	red="\033[0;31m"
	green="\033[0;32m"
	yellow="\033[0;33m"
	reset="\033[0m"

	if [ "${to_stderr}" -eq "0" ]; then
		printf "${yellow}[%s] ${red}%s \$ ${yellow}[NOT] ${green}${cmd}${reset}\n" "$(hostname)" "$(whoami)"
	else
		printf "${yellow}[%s] ${red}%s \$ ${yellow}[NOT] ${green}${cmd}${reset}\n" "$(hostname)" "$(whoami)" >&2
	fi

	if ! sh -c "LANG=C LC_ALL=C ${cmd}"; then
		if [ "${to_stderr}" -eq "0" ]; then
			printf "${green}[%s]${reset}\n" "OK"
		else
			printf "${green}[%s]${reset}\n" "OK" >&2
		fi
		return 0
	else
		if [ "${to_stderr}" -eq "0" ]; then
			printf "${red}[%s]${reset}\n" "NO"
		else
			printf "${red}[%s]${reset}\n" "NO" >&2
		fi
		return 1
	fi
}

sanity_check() {
	_name="${1}"

	if ! run "docker ps | grep '${_name}'"; then
		docker ps
		docker logs "${_name}" || true
		docker stop "${_name}" || true
		exit 1
	fi

	# Test if docker logs works
	if ! run "docker logs ${_name} >/dev/null 2>&1"; then
		docker logs "${_name}" || true
		docker stop "${_name}" || true
		exit 1
	fi

	# Ensure no error string was found
	if ! run_fail "docker logs ${_name} 2>&1 | grep -E '\[ERR\]'"; then
		docker logs "${_name}" || true
		docker stop "${_name}" || true
		exit 1
	fi

	# Ensure no warning string was found
	if ! run_fail "docker logs ${_name} 2>&1 | grep -E '\[WARN\]'"; then
		docker logs "${_name}" || true
		docker stop "${_name}" || true
		exit 1
	fi
}
