#!/usr/bin/env bash

set -e
set -u
set -o pipefail


#################################################################################
# VARIABLES
#################################################################################

###
### Variables
###

NAMED_DIR="/etc/bind"
NAMED_CONF="${NAMED_DIR}/named.conf"
NAMED_OPT_CONF="${NAMED_DIR}/named.conf.options"
NAMED_LOG_CONF="${NAMED_DIR}/named.conf.logging"


###
### Default values of injectables environment variables
###
DEFAULT_DEBUG_ENTRYPOINT=1
DEFAULT_DOCKER_LOGS=0
DEFAULT_DNSSEC_VALIDATE="no"

###
### Default time variables (time in seconds)
###
DEFAULT_TTL_TIME=3600
DEFAULT_REFRESH_TIME=1200
DEFAULT_RETRY_TIME=180
DEFAULT_EXPIRY_TIME=1209600
DEFAULT_MAX_CACHE_TIME=10800



#################################################################################
# HELPER FUNCTIONS
#################################################################################

###
### Log to stdout/stderr
###
log() {
	local type="${1}"     # ok, warn or err
	local message="${2}"  # msg to print
	local debug="${3}"    # 0: only warn and error, >0: ok and info

	local clr_ok="\033[0;32m"
	local clr_info="\033[0;34m"
	local clr_warn="\033[0;33m"
	local clr_err="\033[0;31m"
	local clr_rst="\033[0m"

	if [ "${type}" = "ok" ]; then
		if [ "${debug}" -gt "0" ]; then
			printf "${clr_ok}[OK]   %s${clr_rst}\n" "${message}"
		fi
	elif [ "${type}" = "info" ]; then
		if [ "${debug}" -gt "0" ]; then
			printf "${clr_info}[INFO] %s${clr_rst}\n" "${message}"
		fi
	elif [ "${type}" = "warn" ]; then
		printf "${clr_warn}[WARN] %s${clr_rst}\n" "${message}" 1>&2	# stdout -> stderr
	elif [ "${type}" = "err" ]; then
		printf "${clr_err}[ERR]  %s${clr_rst}\n" "${message}" 1>&2	# stdout -> stderr
	else
		printf "${clr_err}[???]  %s${clr_rst}\n" "${message}" 1>&2	# stdout -> stderr
	fi
}


###
### Wrapper for run_run command
###
run() {
	local cmd="${1}"      # command to execute
	local debug="${2}"    # show commands if debug level > 1

	local clr_red="\033[0;31m"
	local clr_green="\033[0;32m"
	local clr_reset="\033[0m"

	if [ "${debug}" -gt "1" ]; then
		printf "${clr_red}%s \$ ${clr_green}${cmd}${clr_reset}\n" "$( whoami )"
	fi
	/bin/sh -c "LANG=C LC_ALL=C ${cmd}"
}


###
### Check if a value is an integer (positive or negative)
###
is_int() {
	echo "${1}" | grep -Eq '^[-+]?[0-9]+$'
}


###
### Check if a value is a valid IP address
###
is_ip4() {
	# IP is not in correct format
	if ! echo "${1}" | grep -Eq '^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})$'; then
		return 1
	fi

	# 4 IP octets
	local o1
	local o2
	local o3
	local o4

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

###
### Check if a value is a valid IPv4 address with CIDR mask
###
is_ipv4_with_mask() {
	local string="${1}"

	# http://blog.markhatton.co.uk/2011/03/15/regular-expressions-for-ip-addresses-cidr-ranges-and-hostnames/
	if ! echo "${1}" | grep -Eq '^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/(3[0-2]|[1-2][0-9]|[0-9]))$'; then
		return 1
	fi

	# All tests passed
	return 0
}

###
### Check if a value is a valid IPv4 address or IPv4 address with CIDR mask
###
is_ipv4_or_mask() {
	# Is IPv4 or IPv4 with mask
	if is_ip4 "${1}" || is_ipv4_with_mask "${1}"; then
		return 0
	fi

	# Failure
	return 1
}

###
### Check if a value matches any of four predefined address match list names
###
is_address_match_list() {
	# Matches "any" or "none" or "localhost" or "localnets"
	if [[ "${1}" == "any" || "${1}" == "none" || "${1}" == "localhost" || "${1}" == "localnets" ]] ; then
		return 0
	fi

	# Failure
	return 1
}

###
### Check if a value is a valid cname
###
is_cname() {
	local string="${1}"
	# https://stackoverflow.com/questions/106179/regular-expression-to-match-dns-hostname-or-ip-address
	local regex='^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$'

	# Is an IP already
	if is_ip4 "${string}"; then
		return 1
	fi

	# Match for valid CNAME
	echo "${string}" | grep -Eq "${regex}"
}



#################################################################################
# ACTION FUNCTIONS
#################################################################################

# Add Bind options with or without forwarder
#
# @param config_file      Where to store this configuration in.
# @param dnssec_validate  dnssec-validation setting
# @param forwarders       formated (newline separated and trailing semi-colon) string of ip addr
# @param allow_query      formated (newline separated and trailing semi-colon) string of ipv4 addr with optional mask
# @param allow_recursion  formated (newline separated and trailing semi-colon) string of ipv4 addr with optional mask
add_options() {
	local config_file="${1}"
	local dnssec_validate="${2}"
	local forwarders="${3}"
	local allow_query="${4}"
	local allow_recursion="${5}"

	{
		echo "options {"
		echo "    directory \"/var/cache/bind\";"
		echo "    dnssec-validation ${dnssec_validate};"
		echo "    auth-nxdomain no;    # conform to RFC1035"
		echo "    listen-on-v6 { any; };"
		if [ -n "${forwarders}" ]; then
			echo "    forwarders {"
			printf       "${forwarders}"
			echo "    };"
		fi
		if [ -n "${allow_recursion}" ]; then
			echo "    recursion yes;"
			echo "    allow-recursion {"
			printf        "${allow_recursion}"
			echo "    };"
		fi
		if [ -n "${allow_query}" ]; then
			echo "    allow-query {"
			printf        "${allow_query}"
		  echo "    };"
		fi
		echo "};"
	} > "${config_file}"
}


# Add wildcard DNS zone.
#
# @param domain       Domain name to create zone for.
# @param address      IP address to point all records to.
# @param config_file  Configuration file path.
# @param wildcard     1: Enable wildcard, 0: Normal host
# @param reverse      String of reverse DNS name or empty for no reverse DNS
# @param debug_level
add_wildcard_zone() {
	# DNS setting variables
	local domain="${1}"
	local address="${2}"
	local conf_file="${3}"
	local wildcard="${4}"
	local reverse="${5}"
	# DNS time variables
	local ttl_time="${6}"
	local refresh_time="${7}"
	local retry_time="${8}"
	local expiry_time="${9}"
	local max_cache_time="${10}"
	# Debug level for log function
	local debug_level="${11}"


	local reverse_addr
	local reverse_octet
	local conf_path
	local zone_file
	local zone_rev_file
	local serial

	# IP address octets
	local o1
	local o2
	local o3
	local o4

	# Extract IP address octets
	o1="$( echo "${address}" | awk -F '.' '{print $1}' )"
	o2="$( echo "${address}" | awk -F '.' '{print $2}' )"
	o3="$( echo "${address}" | awk -F '.' '{print $3}' )"
	o4="$( echo "${address}" | awk -F '.' '{print $4}' )"

	reverse_addr="${o3}.${o2}.${o1}"
	reverse_octet="${o4}"
	conf_path="$( dirname "${conf_file}" )"
	zone_file="${conf_file}.zone"
	zone_rev_file="${conf_file}.zone.reverse"
	serial="$( date +'%s' )"

	# Create config directory if it does not yet exist
	if [ ! -d "${conf_path}" ]; then
		mkdir -p "${conf_path}"
	fi

	# Config
	{
		echo "zone \"${domain}\" IN {"
		echo "    type master;"
		echo "    allow-transfer { any; };"
		echo "    allow-update { any; };"
		echo "    file \"${zone_file}\";"
		echo "};"
		if [ -n "${reverse}" ]; then
			echo "zone \"${reverse_addr}.in-addr.arpa\" {"
			echo "    type master;"
			echo "    allow-transfer { any; };"
			echo "    allow-update { any; };"
			echo "    file \"${zone_rev_file}\";"
			echo "};"
		fi
	} > "${conf_file}"

	# Forward Zone
	{
		echo "\$TTL  ${ttl_time}"
		echo "@      IN SOA  ${domain}. root.${domain}. ("
		echo "                 ${serial}           ; Serial number of zone file"
		echo "                 ${refresh_time}     ; Refresh time"
		echo "                 ${retry_time}       ; Retry time in case of problem"
		echo "                 ${expiry_time}      ; Expiry time"
		echo "                 ${max_cache_time} ) ; Maximum caching time in case of failed lookups"
		echo ";"
		echo "       IN NS     ns1.${domain}."
		echo "       IN NS     ns2.${domain}."
		echo "       IN A      ${address}"
		echo ";"
		echo "ns1    IN A      ${address}"
		echo "ns2    IN A      ${address}"
		if [ "${wildcard}" -eq "1" ]; then
			echo "*      IN A      ${address}"
		fi
	} > "${zone_file}"

	# Reverse Zone
	if [ -n "${reverse}" ]; then
		{
			echo "\$TTL  ${ttl_time}"
			echo "${reverse_addr}.in-addr.arpa.  IN SOA  ${domain}. root.${domain}. ("
			echo "                 ${serial} ; Serial number of zone file (yyyymmdd##)"
			echo "                 ${refresh_time}     ; Refresh time"
			echo "                 ${retry_time}       ; Retry time in case of problem"
			echo "                 ${expiry_time}      ; Expiry time"
			echo "                 ${max_cache_time} ) ; Maximum caching time in case of failed lookups"
			echo ";"
			echo "${reverse_addr}.in-addr.arpa.       IN      NS      ns1.${domain}."
			echo "${reverse_addr}.in-addr.arpa.       IN      NS      ns2.${domain}."
			echo "${reverse_octet}.${reverse_addr}.in-addr.arpa.     IN      PTR      ${reverse}."
		} > "${zone_rev_file}"
	fi

	# named.conf
	if ! output="$( named-checkconf "${conf_file}" 2>&1 )"; then
		log "err" "Configuration failed." "${debug_level}"
		echo "${output}"
		exit
	elif [ "${debug_level}" -gt "1" ]; then
		echo "${output}"
	fi
	# Zone file
	if ! output="$( named-checkzone "${domain}" "${zone_file}" 2>&1 )"; then
		log "err" "Configuration failed." "${debug_level}"
		echo "${output}"
		exit
	elif [ "${debug_level}" -gt "1" ]; then
		echo "${output}"
	fi
	# Reverse DNS
	if [ -n "${reverse}" ]; then
		if ! output="$( named-checkzone "${reverse_addr}.in-addr.arpa" "${zone_rev_file}" 2>&1 )"; then
			log "err" "Configuration failed." "${debug_level}"
			echo "${output}"
			exit
		elif [ "${debug_level}" -gt "1" ]; then
			echo "${output}"
		fi
	fi
}



#################################################################################
## BOOTSTRAP
#################################################################################

###
### Set Debug level
###
if printenv DEBUG_ENTRYPOINT >/dev/null 2>&1; then
	DEBUG_ENTRYPOINT="$( printenv DEBUG_ENTRYPOINT )"
	if ! is_int "${DEBUG_ENTRYPOINT}"; then
		log "warn" "Wrong value for DEBUG_ENTRYPOINT: '${DEBUG_ENTRYPOINT}'. Setting to ${DEFAULT_DEBUG_ENTRYPOINT}" "2"
		DEBUG_ENTRYPOINT="${DEFAULT_DEBUG_ENTRYPOINT}"
	else
		if [ "${DEBUG_ENTRYPOINT}" -lt "0" ]; then
			log "warn" "Wrong value for DEBUG_ENTRYPOINT: '${DEBUG_ENTRYPOINT}'. Setting to ${DEFAULT_DEBUG_ENTRYPOINT}" "2"
			DEBUG_ENTRYPOINT="${DEFAULT_DEBUG_ENTRYPOINT}"
		elif [ "${DEBUG_ENTRYPOINT}" -gt "2" ]; then
			log "warn" "Wrong value for DEBUG_ENTRYPOINT: '${DEBUG_ENTRYPOINT}'. Setting to ${DEFAULT_DEBUG_ENTRYPOINT}" "2"
			DEBUG_ENTRYPOINT="${DEFAULT_DEBUG_ENTRYPOINT}"
		else
			DEBUG_ENTRYPOINT="${DEBUG_ENTRYPOINT}"
		fi
	fi
else
	DEBUG_ENTRYPOINT="${DEFAULT_DEBUG_ENTRYPOINT}"
fi
log "info" "Debug level: ${DEBUG_ENTRYPOINT}" "${DEBUG_ENTRYPOINT}"



#################################################################################
# ENTRYPOINT
#################################################################################

###
### Re-create BIND default config
###
{
	echo "include \"${NAMED_LOG_CONF}\";"
	echo "include \"${NAMED_OPT_CONF}\";"
	echo "include \"/etc/bind/named.conf.local\";"
	echo "include \"/etc/bind/named.conf.default-zones\";"
} > "${NAMED_CONF}"



###
### Enable Logging to Docker logs
### https://stackoverflow.com/questions/11153958/how-to-enable-named-bind-dns-full-logging#12114139
###
echo > "${NAMED_LOG_CONF}"
if printenv DOCKER_LOGS >/dev/null 2>&1; then
	DOCKER_LOGS="$( printenv DOCKER_LOGS )"
	if [ "${DOCKER_LOGS}" = "1" ]; then
		{
			echo "logging {"
			echo "    category default { default_stderr; };"
			echo "    category queries { default_stderr; };"
			echo "};"
		} > "${NAMED_LOG_CONF}"
		log "info" "BIND logging: to stderr via Docker logs" "${DEBUG_ENTRYPOINT}"
	elif [ "${DOCKER_LOGS}" = "0" ]; then
		log "info" "BIND logging: disabled explicitly" "${DEBUG_ENTRYPOINT}"
	else
		log "warn" "Wrong value for \$DOCKER_LOGS: '${DOCKER_LOGS}'. Only supports: '1' or '0'" "${DEBUG_ENTRYPOINT}"
		DOCKER_LOGS="${DEFAULT_DOCKER_LOGS}"
	fi
fi


###
### DNS Time settings
###
if printenv TTL_TIME >/dev/null 2>&1 && [ -n "$( printenv TTL_TIME )" ]; then
	TTL_TIME="$( printenv TTL_TIME )"
	if is_int "${TTL_TIME}" && [ "${TTL_TIME}" -gt "0" ]; then
		log "info" "Changing DNS TTL time to: ${TTL_TIME} sec" "${DEBUG_ENTRYPOINT}"
	else
		log "warn" "Wrong value for \$TTL_TIME '${TTL_TIME}', defaultint to: ${DEFAULT_TTL_TIME}" "${DEBUG_ENTRYPOINT}"
		TTL_TIME="${DEFAULT_TTL_TIME}"
	fi
else
	log "info" "Using default DNS TTL time: ${DEFAULT_TTL_TIME} sec" "${DEBUG_ENTRYPOINT}"
	TTL_TIME="${DEFAULT_TTL_TIME}"
fi

if printenv REFRESH_TIME >/dev/null 2>&1 && [ -n "$( printenv REFRESH_TIME )" ]; then
	REFRESH_TIME="$( printenv REFRESH_TIME )"
	if is_int "${REFRESH_TIME}" && [ "${REFRESH_TIME}" -gt "0" ]; then
		log "info" "Changing DNS Refresh time to: ${REFRESH_TIME} sec" "${DEBUG_ENTRYPOINT}"
	else
		log "warn" "Wrong value for \$REFRESH_TIME '${REFRESH_TIME}', defaultint to: ${DEFAULT_REFRESH_TIME}" "${DEBUG_ENTRYPOINT}"
		REFRESH_TIME="${DEFAULT_REFRESH_TIME}"
	fi
else
	log "info" "Using default DNS Refresh time: ${DEFAULT_REFRESH_TIME} sec" "${DEBUG_ENTRYPOINT}"
	REFRESH_TIME="${DEFAULT_REFRESH_TIME}"
fi

if printenv RETRY_TIME >/dev/null 2>&1 && [ -n "$( printenv RETRY_TIME )" ]; then
	RETRY_TIME="$( printenv RETRY_TIME )"
	if is_int "${RETRY_TIME}" && [ "${RETRY_TIME}" -gt "0" ]; then
		log "info" "Changing DNS Retry time to: ${RETRY_TIME} sec" "${DEBUG_ENTRYPOINT}"
	else
		log "warn" "Wrong value for \$RETRY_TIME '${RETRY_TIME}', defaultint to: ${DEFAULT_RETRY_TIME}" "${DEBUG_ENTRYPOINT}"
		RETRY_TIME="${DEFAULT_RETRY_TIME}"
	fi
else
	log "info" "Using default DNS Retry time: ${DEFAULT_RETRY_TIME} sec" "${DEBUG_ENTRYPOINT}"
	RETRY_TIME="${DEFAULT_RETRY_TIME}"
fi

if printenv EXPIRY_TIME >/dev/null 2>&1 && [ -n "$( printenv EXPIRY_TIME )" ]; then
	EXPIRY_TIME="$( printenv EXPIRY_TIME )"
	if is_int "${EXPIRY_TIME}" && [ "${EXPIRY_TIME}" -gt "0" ]; then
		log "info" "Changing DNS Expiry time to: ${EXPIRY_TIME} sec" "${DEBUG_ENTRYPOINT}"
	else
		log "warn" "Wrong value for \$EXPIRY_TIME '${EXPIRY_TIME}', defaultint to: ${DEFAULT_EXPIRY_TIME}" "${DEBUG_ENTRYPOINT}"
		EXPIRY_TIME="${DEFAULT_EXPIRY_TIME}"
	fi
else
	log "info" "Using default DNS Expiry time: ${DEFAULT_EXPIRY_TIME} sec" "${DEBUG_ENTRYPOINT}"
	EXPIRY_TIME="${DEFAULT_EXPIRY_TIME}"
fi

if printenv MAX_CACHE_TIME >/dev/null 2>&1 && [ -n "$( printenv MAX_CACHE_TIME )" ]; then
	MAX_CACHE_TIME="$( printenv MAX_CACHE_TIME )"
	if is_int "${MAX_CACHE_TIME}" && [ "${MAX_CACHE_TIME}" -gt "0" ]; then
		log "info" "Changing DNS Max Cache time to: ${MAX_CACHE_TIME} sec" "${DEBUG_ENTRYPOINT}"
	else
		log "warn" "Wrong value for \$MAX_CACHE_TIME '${MAX_CACHE_TIME}', defaultint to: ${DEFAULT_MAX_CACHE_TIME}" "${DEBUG_ENTRYPOINT}"
		MAX_CACHE_TIME="${DEFAULT_MAX_CACHE_TIME}"
	fi
else
	log "info" "Using default DNS Max Cache time: ${DEFAULT_MAX_CACHE_TIME} sec" "${DEBUG_ENTRYPOINT}"
	MAX_CACHE_TIME="${DEFAULT_MAX_CACHE_TIME}"
fi



###
### Add wildcard DNS
###
if printenv WILDCARD_DNS >/dev/null 2>&1; then

	# Convert 'com=1.2.3.4[=com],de=2.3.4.5' into newline separated string:
	#  com=1.2.3.4[=com]
	#  de=2.3.4.5
	echo "${WILDCARD_DNS}" | sed 's/,/\n/g' | while read line ; do
		my_dom="$( echo "${line}" | awk -F '=' '{print $1}' | xargs -0 )"  # domain
		my_add="$( echo "${line}" | awk -F '=' '{print $2}' | xargs -0 )"  # IP address
		my_rev="$( echo "${line}" | awk -F '=' '{print $3}' | xargs -0 )"  # Reverse DNS record
		my_cfg="${NAMED_DIR}/devilbox-wildcard_dns.${my_dom}.conf"

		# If a CNAME was provided, try to resolve it to an IP address, otherwhise skip it
		if is_cname "${my_add}"; then
			# Try ping command first
			if ! tmp="$( ping -c1 "${my_add}" 2>&1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1 )"; then
				tmp="${my_add}"
			fi
			if ! is_ip4 "${tmp}"; then
				# Try dig command second
				tmp="$( dig @8.8.8.8 +short "${my_add}" A )"
				if ! is_ip4 "${tmp}"; then
					log "warn" "CNAME '${my_add}' could not be resolved. Skipping to add wildcard" "${DEBUG_ENTRYPOINT}"
					continue;
				fi
			fi
			log "info" "CNAME '${my_add}' resolved to: ${tmp}" "${DEBUG_ENTRYPOINT}"
			my_add="${tmp}"
		fi

		# If specified address is not a valid IPv4 address, skip it
		if ! is_ip4 "${my_add}"; then
			log "warn" "Invalid IP address '${my_add}': for *.${my_dom} -> ${my_add}. Skipping to add wildcard" "${DEBUG_ENTRYPOINT}"
			continue;
		fi

		if [ -n "${my_rev}" ]; then
			log "info" "Adding wildcard DNS: *.${my_dom} -> ${my_add} (PTR: ${my_rev})" "${DEBUG_ENTRYPOINT}"
		else
			log "info" "Adding wildcard DNS: *.${my_dom} -> ${my_add}" "${DEBUG_ENTRYPOINT}"
		fi

		echo "include \"${my_cfg}\";" >> "${NAMED_CONF}"
		add_wildcard_zone "${my_dom}" "${my_add}" "${my_cfg}" "1" "${my_rev}" \
			"${TTL_TIME}" "${REFRESH_TIME}" "${RETRY_TIME}" "${EXPIRY_TIME}" "${MAX_CACHE_TIME}" \
			"${DEBUG_ENTRYPOINT}"
	done
fi



###
### Add extra hosts
###
if printenv EXTRA_HOSTS >/dev/null 2>&1 && [ -n "$( printenv EXTRA_HOSTS )" ]; then

	# Convert 'com=1.2.3.4[=com],de=2.3.4.5' into newline separated string:
	#  com=1.2.3.4
	#  de=2.3.4.5
	echo "${EXTRA_HOSTS}" | sed 's/,/\n/g' | while read line ; do
		my_dom="$( echo "${line}" | awk -F '=' '{print $1}' | xargs -0 )"  # domain
		my_add="$( echo "${line}" | awk -F '=' '{print $2}' | xargs -0 )"  # IP address
		my_rev="$( echo "${line}" | awk -F '=' '{print $3}' | xargs -0 )"  # Reverse DNS record
		my_cfg="${NAMED_DIR}/devilbox-extra_hosts.${my_dom}.conf"

		# If a CNAME was provided, try to resolve it to an IP address, otherwhise skip it
		if is_cname "${my_add}"; then
			# Try ping command first
			if ! tmp="$( ping -c1 "${my_add}" 2>&1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1 )"; then
				tmp="${my_add}"
			fi
			if ! is_ip4 "${tmp}"; then
				# Try dig command second
				tmp="$( dig @8.8.8.8 +short "${my_add}" A )"
				if ! is_ip4 "${tmp}"; then
					log "warn" "CNAME '${my_add}' could not be resolved. Skipping to add extra host" "${DEBUG_ENTRYPOINT}"
					continue;
				fi
			fi
			log "info" "CNAME '${my_add}' resolved to: ${tmp}" "${DEBUG_ENTRYPOINT}"
			my_add="${tmp}"
		fi

		# If specified address is not a valid IPv4 address, skip it
		if ! is_ip4 "${my_add}"; then
			log "warn" "Invalid IP address '${my_add}': for ${my_dom} -> ${my_add}. Skipping to add extra host" "${DEBUG_ENTRYPOINT}"
			continue;
		fi

		if [ -n "${my_rev}" ]; then
			log "info" "Adding extra host: ${my_dom} -> ${my_add} (PTR: ${my_rev})" "${DEBUG_ENTRYPOINT}"
		else
			log "info" "Adding extra host: ${my_dom} -> ${my_add}" "${DEBUG_ENTRYPOINT}"
		fi

		echo "include \"${my_cfg}\";" >> "${NAMED_CONF}"
		add_wildcard_zone "${my_dom}" "${my_add}" "${my_cfg}" "0" "${my_rev}" \
			"${TTL_TIME}" "${REFRESH_TIME}" "${RETRY_TIME}" "${EXPIRY_TIME}" "${MAX_CACHE_TIME}" \
			"${DEBUG_ENTRYPOINT}"
	done
else
	log "info" "Not adding any extra hosts" "${DEBUG_ENTRYPOINT}"
fi



###
### Allow query
###
_allow_query_block=""
if ! printenv ALLOW_QUERY >/dev/null 2>&1; then
	log "info" "\$ALLOW_QUERY not set." "${DEBUG_ENTRYPOINT}"
	log "info" "DNS query rules will not be set" "${DEBUG_ENTRYPOINT}"
else
	# Transform into newline separated forwards and loop over:
	#   x.x.x.x\n
	#   y.y.y.y\n
	while read ip ; do
		ip="$( echo "${ip}" | xargs -0 )"

		if ! is_ipv4_or_mask "${ip}" && ! is_address_match_list "${ip}"; then
			log "err" "ALLOW_QUERY error: not a valid IPv4 address with optional mask: ${ip}" "${DEBUG_ENTRYPOINT}"
			exit 1
		fi

		if [ -z "${_allow_query_block}" ]; then
			_allow_query_block="        ${ip};"
		else
			_allow_query_block="${_allow_query_block}\n        ${ip};"
		fi
	done <<< "$(echo "$( printenv ALLOW_QUERY )" | sed 's/,/\n/g' )"


	if [ -z "${_allow_query_block}" ]; then
		log "err" "ALLOW_QUERY error: variable specified, but no IP addresses found." "${DEBUG_ENTRYPOINT}"
		exit 1
	fi

	log "info" "Adding custom allow-query options: ${ALLOW_QUERY}" "${DEBUG_ENTRYPOINT}"
	# Add quotes here
	_allow_query_block="${_allow_query_block}"
fi



###
### Allow recursion
###
_allow_recursion_block=""
if ! printenv ALLOW_RECURSION >/dev/null 2>&1; then
	log "info" "\$ALLOW_RECURSION not set." "${DEBUG_ENTRYPOINT}"
	log "info" "DNS recursion rules will not be set" "${DEBUG_ENTRYPOINT}"
else
	# Transform into newline separated forwards and loop over:
	#   x.x.x.x\n
	#   y.y.y.y\n
	while read ip ; do
		ip="$( echo "${ip}" | xargs -0 )"

		if ! is_ipv4_or_mask "${ip}" && ! is_address_match_list "${ip}"; then
			log "err" "ALLOW_RECURSION error: not a valid IPv4 address with optional mask: ${ip}" "${DEBUG_ENTRYPOINT}"
			exit 1
		fi

		if [ -z "${_allow_recursion_block}" ]; then
			_allow_recursion_block="        ${ip};"
		else
			_allow_recursion_block="${_allow_recursion_block}\n        ${ip};"
		fi
	done <<< "$(echo "$( printenv ALLOW_RECURSION )" | sed 's/,/\n/g' )"


	if [ -z "${_allow_recursion_block}" ]; then
		log "err" "ALLOW_RECURSION error: variable specified, but no IP addresses found." "${DEBUG_ENTRYPOINT}"
		exit 1
	fi

	log "info" "Adding custom allow-recursion options: ${ALLOW_RECURSION}" "${DEBUG_ENTRYPOINT}"
	# Add quotes here
	_allow_recursion_block="${_allow_recursion_block}"
fi



###
### DNSSEC validation
###
if printenv DNSSEC_VALIDATE >/dev/null 2>&1; then
	DNSSEC_VALIDATE="$( printenv DNSSEC_VALIDATE )"
	if [ "${DNSSEC_VALIDATE}" = "auto" ]; then
		DNSSEC_VALIDATE="${DNSSEC_VALIDATE}"
	elif [ "${DNSSEC_VALIDATE}" = "yes" ]; then
		DNSSEC_VALIDATE="${DNSSEC_VALIDATE}"
	elif [ "${DNSSEC_VALIDATE}" = "no" ]; then
		DNSSEC_VALIDATE="${DNSSEC_VALIDATE}"
	else
		log "warning" "Wrong value for DNSSEC_VALIDATE: '${DNSSEC_VALIDATE}'. Setting it to '${DEFAULT_DNSSEC_VALIDATE}'" "${DEBUG_ENTRYPOINT}"
		DNSSEC_VALIDATE="${DEFAULT_DNSSEC_VALIDATE}"
	fi
else
	DNSSEC_VALIDATE="${DEFAULT_DNSSEC_VALIDATE}"
fi
log "info" "DNSSEC Validation: ${DNSSEC_VALIDATE}" "${DEBUG_ENTRYPOINT}"



###
### Forwarder
###
if ! printenv DNS_FORWARDER >/dev/null 2>&1; then
	log "info" "\$DNS_FORWARDER not set." "${DEBUG_ENTRYPOINT}"
	log "info" "No custom DNS server will be used as forwarder" "${DEBUG_ENTRYPOINT}"

	add_options "${NAMED_OPT_CONF}" "${DNSSEC_VALIDATE}" "" "${_allow_query_block}" "${_allow_recursion_block}"
else

	# To be pupulated
	_forwarders_block=""

	# Transform into newline separated forwards and loop over:
	#   x.x.x.x\n
	#   y.y.y.y\n
	while read ip ; do
		ip="$( echo "${ip}" | xargs -0 )"

		if ! is_ip4 "${ip}"; then
			log "err" "DNS_FORWARDER error: not a valid IP address: ${ip}" "${DEBUG_ENTRYPOINT}"
			exit 1
		fi

		if [ -z "${_forwarders_block}" ]; then
			_forwarders_block="        ${ip};"
		else
			_forwarders_block="${_forwarders_block}\n        ${ip};"
		fi
	done <<< "$(echo "$( printenv DNS_FORWARDER )" | sed 's/,/\n/g' )"


	if [ -z "${_forwarders_block}" ]; then
		log "err" "DNS_FORWARDER error: variable specified, but no IP addresses found." "${DEBUG_ENTRYPOINT}"
		exit 1
	fi

	log "info" "Adding custom DNS forwarder: ${DNS_FORWARDER}" "${DEBUG_ENTRYPOINT}"
	add_options "${NAMED_OPT_CONF}" "${DNSSEC_VALIDATE}" "${_forwarders_block}" "${_allow_query_block}" "${_allow_recursion_block}"
fi

###
### Start
###
log "info" "Starting $( named -V | grep -oiE '^BIND[[:space:]]+[0-9.]+' )" "${DEBUG_ENTRYPOINT}"
named-checkconf "${NAMED_CONF}"
exec /usr/sbin/named -4 -c /etc/bind/named.conf -u bind -f
