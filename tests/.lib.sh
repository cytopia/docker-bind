#!/bin/sh

set -e
set -u

run() {
	cmd="${1}"
	to_stdout=0
	cmd_to_stderr=0

	# Output to stdout instead?
	if [ "${#}" -gt "1" ]; then
		to_stdout="${2}"
	fi

	# Command output to stderr as well
	if [ "${#}" -gt "2" ]; then
		cmd_to_stderr="${3}"
	fi

	red="\033[0;31m"
	green="\033[0;32m"
	yellow="\033[0;33m"
	reset="\033[0m"

	if [ "${to_stdout}" -eq "0" ]; then
		printf "${yellow}[%s] ${red}%s \$ ${green}${cmd}${reset}\n" "$(hostname)" "$(whoami)" >&2
	else
		printf "${yellow}[%s] ${red}%s \$ ${green}${cmd}${reset}\n" "$(hostname)" "$(whoami)"
	fi

	if OUT="$( bash -c "set -eu && set -o pipefail && LANG=C LC_ALL=C ${cmd}" )"; then
		# Output command
		if [ -n "${OUT}" ]; then
			echo "${OUT}"
			if [ "${cmd_to_stderr}" = "1" ]; then
				>&2 echo "${OUT}"
			fi
		fi
		# Output exit code
		if [ "${to_stdout}" -eq "0" ]; then
			printf "${green}[%s]${reset}\n" "OK" >&2
		else
			printf "${green}[%s]${reset}\n" "OK"
		fi
		return 0
	else
		# Output command
		if [ -n "${OUT}" ]; then
			echo "${OUT}"
			if [ "${cmd_to_stderr}" = "1" ]; then
				>&2 echo "${OUT}"
			fi
		fi
		# Output exit code
		if [ "${to_stdout}" -eq "0" ]; then
			printf "${red}[%s]${reset}\n" "NO" >&2
		else
			printf "${red}[%s]${reset}\n" "NO"
		fi
		return 1
	fi
}

run_fail() {
	cmd="${1}"
	to_stdout=0

	# Output to stdout instead?
	if [ "${#}" -eq "2" ]; then
		to_stdout="${2}"
	fi

	red="\033[0;31m"
	green="\033[0;32m"
	yellow="\033[0;33m"
	reset="\033[0m"

	if [ "${to_stdout}" -eq "0" ]; then
		printf "${yellow}[%s] ${red}%s \$ ${yellow}[NOT] ${green}${cmd}${reset}\n" "$(hostname)" "$(whoami)" >&2
	else
		printf "${yellow}[%s] ${red}%s \$ ${yellow}[NOT] ${green}${cmd}${reset}\n" "$(hostname)" "$(whoami)"
	fi

	if ! sh -c "LANG=C LC_ALL=C ${cmd}"; then
		if [ "${to_stdout}" -eq "0" ]; then
			printf "${green}[%s]${reset}\n" "OK" >&2
		else
			printf "${green}[%s]${reset}\n" "OK"
		fi
		return 0
	else
		if [ "${to_stdout}" -eq "0" ]; then
			printf "${red}[%s]${reset}\n" "NO" >&2
		else
			printf "${red}[%s]${reset}\n" "NO"
		fi
		return 1
	fi
}

sanity_check() {
	_name="${1}"
	_file="${2:-}"

	if ! run "docker ps | grep '${_name}'"; then
		docker ps
		docker logs "${_name}" || true
		docker stop "${_name}" || true
		return 1
	fi

	# Test if docker logs works
	if ! run "docker logs ${_name}"; then
		docker stop "${_name}" || true
		return 1
	fi

	# Ensure no error string was found
	if ! run_fail "docker logs ${_name} 2>&1 | grep -E '\[ERR\]'"; then
		docker logs "${_name}" || true
		docker stop "${_name}" || true
		return 1
	fi

	# Ensure no warning string was found
	if ! run_fail "docker logs ${_name} 2>&1 | grep -E '\[WARN\]'"; then
		docker logs "${_name}" || true
		docker stop "${_name}" || true
		return 1
	fi
}


docker_stop() {
	_name="${1}"

	run "docker stop ${_name}" || true
	run "docker kill ${_name} >/dev/null 2>&1 || true" >/dev/null 2>&1
	run "sleep 2"
}
