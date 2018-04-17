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

	# Re-create default config
	(
		echo "include \"/etc/bind/named.conf.options\";"
		echo "include \"/etc/bind/named.conf.local\";"
		echo "include \"/etc/bind/named.conf.default-zones\";"
	) > /etc/bind/named.conf

	# Add custom config
	run "echo 'include \"${conf_file}\";' >> /etc/bind/named.conf"

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
		if [ -n "$CUSTOM_DNS" ]
		then
			CUSTOM_DNS_LINES=$(echo "$CUSTOM_DNS" | sed "s/=/ IN A  /g; s/,/\n/g;")
			echo $CUSTOM_DNS_LINES
			log "info" "Adding custom DNS: ${CUSTOM_DNS_LINES}"
		fi
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

	# Re-create default config
	(
		echo "include \"/etc/bind/named.conf.options\";"
		echo "include \"/etc/bind/named.conf.local\";"
		echo "include \"/etc/bind/named.conf.default-zones\";"
	) > /etc/bind/named.conf

fi


###
### Add custom forwarder IP's
###
if ! set | grep '^DNS_FORWARDER=' >/dev/null 2>&1; then
	log "warn" "\$DNS_FORWARDER not set."
	log "warn" "No custom DNS server will be used as forwarder"

	# Restore defaults
	(
		echo "options {"
		echo "    directory \"/var/cache/bind\";"
		echo "    dnssec-validation auto;"
		echo "    auth-nxdomain no;    # conform to RFC1035"
		echo "    listen-on-v6 { any; };"
		echo "};"
	) > /etc/bind/named.conf.options
else

	# To be pupulated
	_forwarders_block=""

	# Transform into newline separated forwards:
	#   x.x.x.x\n
	#   y.y.y.y\n
	_forwards="$( echo "${DNS_FORWARDER}" | sed 's/[[:space:]]*//g' | sed 's/,/\n/g' )"

	# loop over them
	IFS='
	'
	for ip in ${_forwards}; do
		if ! isip "${ip}"; then
			log "err" "DNS_FORWARDER error: not a valid IP address: ${ip}"
			exit 1
		fi

		if [ "${_forwarders_block}" = "" ]; then
			_forwarders_block="\t\t${ip};"
		else
			_forwarders_block="${_forwarders_block}\n\t\t${ip};"
		fi
	done

	if [ "${_forwarders_block}" = "" ]; then
		log "err" "DNS_FORWARDER error: variable specified, but no IP addresses found."
		exit 1
	fi

	log "info" "Adding custom DNS forwarder: ${DNS_FORWARDER}"

	# forwarders {
	#     x.x.x.x;
	#     y.y.y.y;
	# };
	(
		echo "options {"
		echo "    directory \"/var/cache/bind\";"
		echo "    dnssec-validation auto;"
		echo "    auth-nxdomain no;    # conform to RFC1035"
		echo "    listen-on-v6 { any; };"
		echo "    forwarders {"
		echo "${_forwarders_block}"
		echo "    };"
		echo "};"
	) > /etc/bind/named.conf.options
fi



###
### Start
###
log "info" "Starting $( named -V | grep -oiE '^BIND[[:space:]]+[0-9.]+' )"
exec /usr/sbin/named -4 -c /etc/bind/named.conf -u bind -f
