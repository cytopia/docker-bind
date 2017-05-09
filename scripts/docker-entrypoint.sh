#!/bin/sh -eu

###
### Variables
###
DEBUG_COMMANDS=0



###
### Functions
###
run() {
	_cmd="${1}"
	_debug="0"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"


	# If 2nd argument is set and enabled, allow debug command
	if [ "${#}" = "2" ]; then
		if [ "${2}" = "1" ]; then
			_debug="1"
		fi
	fi


	if [ "${DEBUG_COMMANDS}" = "1" ] || [ "${_debug}" = "1" ]; then
		printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	fi
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}

log() {
	_lvl="${1}"
	_msg="${2}"

	_clr_ok="\033[0;32m"
	_clr_info="\033[0;34m"
	_clr_warn="\033[0;33m"
	_clr_err="\033[0;31m"
	_clr_rst="\033[0m"

	if [ "${_lvl}" = "ok" ]; then
		printf "${_clr_ok}[OK]   %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "info" ]; then
		printf "${_clr_info}[INFO] %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "warn" ]; then
		printf "${_clr_warn}[WARN] %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	elif [ "${_lvl}" = "err" ]; then
		printf "${_clr_err}[ERR]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	else
		printf "${_clr_err}[???]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	fi
}

# Test if argument is an integer.
#
# @param  mixed
# @return integer	0: is number | 1: not a number
isint(){
	printf "%d" "${1}" >/dev/null 2>&1 && return 0 || return 1;
}
isip() {
	# IP is not in correct format
	if ! echo "${1}" | grep -Eq '^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})$'; then
		return 1
	fi

	# Get each octet
	o1="$( echo "${1}" | awk -F'.' '{print $1}' )"
	o2="$( echo "${1}" | awk -F'.' '{print $2}' )"
	o3="$( echo "${1}" | awk -F'.' '{print $3}' )"
	o4="$( echo "${1}" | awk -F'.' '{print $4}' )"

	# Cannot start with 0 and all must be below 256
	if [ "${o1}" -lt "1" ] || \
		[ "${o1}" -gt "255" ] || \
		[ "${o2}" -gt "255" ] || \
		[ "${o3}" -gt "255" ] || \
		[ "${o4}" -gt "255" ]; then
		return 1
	fi

	# All tests passed
	return 0
}




################################################################################
# BOOTSTRAP
################################################################################

if set | grep '^DEBUG_COMPOSE_ENTRYPOINT='  >/dev/null 2>&1; then
	if [ "${DEBUG_COMPOSE_ENTRYPOINT}" = "1" ]; then
		DEBUG_COMMANDS=1
	fi
fi


################################################################################
# MAIN ENTRY POINT
################################################################################



###
### Add wildcard DNS record?
###
if set | grep '^WILDCARD_DOMAIN=' >/dev/null 2>&1 && set | grep '^WILDCARD_ADDRESS=' >/dev/null 2>&1; then
	if ! isip "${WILDCARD_ADDRESS}"; then
		log "err" "Value of \$WILDCARD_ADDRESS is not a valid IP Address: ${WILDCARD_ADDRESS}"
		exit 1
	fi

	log "info" "Adding wildcard DNS record: '*.${WILDCARD_DOMAIN}' -> '${WILDCARD_ADDRESS}'"

	conf_file="/etc/bind/custom-named.conf.${WILDCARD_DOMAIN}"
	zone_file="/etc/bind/custom-db.${WILDCARD_DOMAIN}"

	# Add our config
	echo "include \"${conf_file}\";" >> /etc/bind/named.conf

	# Config
	(
		echo "zone \"${WILDCARD_DOMAIN}\" IN {"
		echo "    type master;"
		echo "    allow-transfer { any; };"
		echo "    file \"${zone_file}\";"
		echo "};"
	) > "${conf_file}"

	# Zone
	(
		echo "@  IN SOA  . root.acmecorp.com. ("
		echo "             20130903  ; serial number of zone file (yyyymmdd##)"
		echo "             604800    ; refresh time"
		echo "             86400     ; retry time in case of problem"
		echo "             2419200   ; expiry time"
		echo "             604800)   ; maximum caching time in case of failed lookups"
		echo "   IN NS     ."
		echo "   IN A      ${WILDCARD_ADDRESS}"
		echo "*  IN A      ${WILDCARD_ADDRESS}"
	) > "${zone_file}"

else

	if ! set | grep '^WILDCARD_DOMAIN=' >/dev/null 2>&1; then
		log "info" "\$WILDCARD_DOMAIN not set, not adding custom DNS record."
	fi
	if ! set | grep '^WILDCARD_ADDRESS=' >/dev/null 2>&1; then
		log "info" "\$WILDCARD_ADDRESS not set, not adding custom DNS record."
	fi
fi


###
### Configure
###
#run "sed -i'' 's/^[[:space:]]*listen-on-v6.*//g' /etc/bind/named.conf.options"
#run "sed -i'' 's/^};/\tforwarders {\n\t\t8.8.4.4;\n\t};\n};/' /etc/bind/named.conf.options"


###
### Fix permissions
###
run "mkdir -p /var/run/named"
run "chown -R bind:bind /var/run/named"



###
### Start
###
log "info" "Starting $( named -V | grep -oiE '^BIND[[:space:]]+[0-9.]+' )"
exec /usr/sbin/named -4 -u bind -g
