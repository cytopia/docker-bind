#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# Enable bash debugging for this entrypoint script
if [ "${DEBUG:-}" = "1" ]; then
	set -x
fi


####################################################################################################
###
### (1/6) VARIABLES
###
####################################################################################################

###
### Variables
###

NAMED_DIR="/etc/bind"
NAMED_CONF="${NAMED_DIR}/named.conf"
NAMED_OPT_CONF="${NAMED_DIR}/named.conf.options"
NAMED_LOG_CONF="${NAMED_DIR}/named.conf.logging"
NAMED_CUST_CONF="${NAMED_DIR}/custom/conf"
NAMED_CUST_ZONE="${NAMED_DIR}/custom/zone"

mkdir -p "${NAMED_CUST_CONF}"
mkdir -p "${NAMED_CUST_ZONE}"


###
### FQDN of primary nameserver.
### Defaults to current hostname if not otherwise specified.
### When overwriting, use an FQDN by which this container is reachable.
### http://rscott.org/dns/soa.html
###
DEFAULT_MNAME="$( hostname -A | sed 's/\s$//g' | xargs -0 )"


###
### Contact Email
### All dot characters '.' must be escaped with an backslash '\'
### The actual @ character must be an unescaped dot character '.'
###
DEFAULT_RNAME="admin.${DEFAULT_MNAME}"


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



####################################################################################################
###
### (2/6) HELPER FUNCTIONS
###
####################################################################################################

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
### Log configuration file
###
log_file() {
	local filename="${1}"

	echo
	printf "%0.s-" {1..80}; echo
	echo "${filename}"
	printf "%0.s-" {1..80}; echo
	cat "${filename}"
	printf "%0.s^" {1..80}; echo
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
### Check if a value has multiple lines
###
is_multiline() {
	(( $(grep -c . <<<"${1}") > 1 ))
}


###
### Check if a value is a valid IP address
###
is_ip4_addr() {
	local regex='^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})$'

	# Invalid input
	if is_multiline "${1}"; then
		return 1
	fi
	# Invalid IPv4
	if ! echo "${1}" | grep -Eq "${regex}"; then
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
}


###
### Check if a value is a valid IPv4 address with CIDR mask
###
is_ipv4_cidr() {
	# http://blog.markhatton.co.uk/2011/03/15/regular-expressions-for-ip-addresses-cidr-ranges-and-hostnames/
	local regex='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/(3[0-2]|[1-2][0-9]|[0-9]))$'

	# Invalid input
	if is_multiline "${1}"; then
		return 1
	fi
	# Invalid IPv4 CIDR
	if ! echo "${1}" | grep -Eq "${regex}"; then
		return 1
	fi
}


###
### Check if a value is a valid IPv4 address or IPv4 address with CIDR mask
###
is_ipv4_addr_or_ipv4_cidr() {
	# Is IPv4 or IPv4 with mask
	if is_ip4_addr "${1}" || is_ipv4_cidr "${1}"; then
		return 0
	fi
}


###
### Check if a value is a valid cname
###
is_cname() {
	# https://stackoverflow.com/questions/106179/regular-expression-to-match-dns-hostname-or-ip-address
	local regex='^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$'

	# Is an IP already
	if is_ip4_addr "${1}" || is_ipv4_cidr "${1}"; then
		return 1
	fi

	# Match for valid CNAME
	echo "${1}" | grep -Eq "${regex}"
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



####################################################################################################
###
### (3/6) ACTION FUNCTIONS
###
####################################################################################################

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
	local response_policy="${6}"

	{
		echo "options {"
		echo "    directory \"/var/cache/bind\";"
		echo "    dnssec-validation ${dnssec_validate};"
		echo "    auth-nxdomain no;    # conform to RFC1035"
		echo "    listen-on-v6 { any; };"
		if [ -n "${response_policy}" ]; then
			echo "    response-policy { zone \"${response_policy}\"; };"
		fi
		if [ -n "${forwarders}" ]; then
			echo "    forwarders {"
			# shellcheck disable=SC2059
			printf       "${forwarders}\n"
			echo "    };"
		fi
		if [ -n "${allow_recursion}" ]; then
			echo "    recursion yes;"
			echo "    allow-recursion {"
			# shellcheck disable=SC2059
			printf        "${allow_recursion}\n"
			echo "    };"
		fi
		if [ -n "${allow_query}" ]; then
			echo "    allow-query {"
			# shellcheck disable=SC2059
			printf        "${allow_query}\n"
		  echo "    };"
		fi
		echo "};"
	} > "${config_file}"

	# Output configuration file
	log_file "${config_file}"
}


###
### Add Reverse zone
###
add_rev_zone() {
	# Zone variables
	local addr="${1}"  # A.B.C.D
	local name="${2}"  # Domain / FQDN
	local zone="${3}"  # C.B.A.in-addr.arpa
	local ptr="${4}"   # D.C.B.A.in-addr.arpa

	# DNS timing variables
	local ttl_time="${5}"
	local refresh_time="${6}"
	local retry_time="${7}"
	local expiry_time="${8}"
	local max_cache_time="${9}"
	local serial
	serial="$( date +'%s' )"

	local debug_level="${10}"

	# Config file
	if [ ! -f "${NAMED_CUST_CONF}/${zone}.conf" ]; then
		{
			echo "zone \"${zone}\" {"
			echo "    type master;"
			echo "    allow-transfer { any; };"
			echo "    allow-update { any; };"
			echo "    file \"${NAMED_CUST_ZONE}/${zone}\";"
			echo "};"
		} > "${NAMED_CUST_CONF}/${zone}.conf"

		# Append config to bind
		echo "include \"${NAMED_CUST_CONF}/${zone}.conf\";" >> "${NAMED_CONF}"
	fi

	# Reverse zone file
	if [ ! -f "${NAMED_CUST_ZONE}/${zone}" ]; then
		{
			printf "\$TTL %s\n" "${ttl_time}"
			printf "%-29s   IN   SOA     %s %s (\n"    "@" "${DEFAULT_MNAME}." "${DEFAULT_RNAME}."
			printf "%-44s %-15s; Serial number\n"      ""  "${serial}"
			printf "%-44s %-15s; Refresh time\n"       ""  "${refresh_time}"
			printf "%-44s %-15s; Retry time\n"         ""  "${retry_time}"
			printf "%-44s %-15s; Expiry time\n"        ""  "${expiry_time}"
			printf "%-44s %-15s; Negative Cache TTL\n" ""  "${max_cache_time}"
			echo ")"
			echo
			echo "; NS Records"
			printf "%-29s   IN   NS      %-20s\n"    "${zone}." "${DEFAULT_MNAME}."
			echo
			echo "; PTR Records"
			printf "%-29s   IN   PTR     %-20s %s\n" "${ptr}." "${name}." "; ${addr}"

		} > "${NAMED_CUST_ZONE}/${zone}"
	else
		{
			printf "%-29s   IN   PTR     %-20s %s\n" "${ptr}." "${name}." "; ${addr}"
		} >> "${NAMED_CUST_ZONE}/${zone}"
	fi

	# Validate .conf file
	if ! output="$( named-checkconf "${NAMED_CUST_CONF}/${zone}.conf" 2>&1 )"; then
		log "err" "Configuration failed." "${debug_level}"
		if [ -n "${output}" ]; then
			echo "${output}"
		fi
		log_file "${NAMED_CUST_CONF}/${zone}.conf"
		exit 1
	elif [ "${debug_level}" -gt "1" ]; then
		if [ -n "${output}" ]; then
			echo "${output}"
		fi
	fi
	# Validate reverze zone file
	if ! output="$( named-checkzone "${zone}" "${NAMED_CUST_ZONE}/${zone}" 2>&1 )"; then
		log "err" "Configuration failed." "${debug_level}"
		if [ -n "${output}" ]; then
			echo "${output}"
		fi
		log_file "${NAMED_CUST_ZONE}/${zone}"
		exit 1
	elif [ "${debug_level}" -gt "1" ]; then
		if [ -n "${output}" ]; then
			echo "${output}"
		fi
	fi
}


###
### Add Forward zone (response policy zone)
###
add_fwd_zone() {
	# Zone variables
	local domain="${1}"  # The domain to translate
	local record="${2}"  # The record type (A, CNAME, etc)
	local target="${3}"  # The target to translate domain to

	# DNS timing variables
	local ttl_time="${4}"
	local refresh_time="${5}"
	local retry_time="${6}"
	local expiry_time="${7}"
	local max_cache_time="${8}"
	local serial
	serial="$( date +'%s' )"

	local debug_level="${9}"

	# Config file
	if [ ! -f "${NAMED_CUST_CONF}/rpz.conf" ]; then
		{
			echo "zone \"rpz\" IN {"
			echo "    type master;"
			echo "    allow-transfer { any; };"
			echo "    allow-update { any; };"
			echo "    file \"${NAMED_CUST_ZONE}/rpz\";"
			echo "};"
		} > "${NAMED_CUST_CONF}/rpz.conf"

		# Append config to bind
		echo "include \"${NAMED_CUST_CONF}/rpz.conf\";" >> "${NAMED_CONF}"
	fi

	# forward zone file
	if [ ! -f "${NAMED_CUST_ZONE}/rpz" ]; then
		{
			#printf "\$ORIGIN %s\n" "${DEFAULT_MNAME}"
			printf "\$TTL %s\n" "${ttl_time}"
			printf "%-29s   IN   SOA     %s %s (\n"    "@" "${DEFAULT_MNAME}." "${DEFAULT_RNAME}."
			printf "%-44s %-15s; Serial number\n"      ""  "${serial}"
			printf "%-44s %-15s; Refresh time\n"       ""  "${refresh_time}"
			printf "%-44s %-15s; Retry time\n"         ""  "${retry_time}"
			printf "%-44s %-15s; Expiry time\n"        ""  "${expiry_time}"
			printf "%-44s %-15s; Negative Cache TTL\n" ""  "${max_cache_time}"
			echo ")"
			echo
			echo "; NS Records"
			printf "%-29s   IN   %-7s %s\n" ""          "NS"        "${DEFAULT_MNAME}."
			echo
			echo "; Custom Records"
			printf "%-29s   IN   %-7s %s\n" "${domain}" "${record}" "${target}"
		} > "${NAMED_CUST_ZONE}/rpz"
	else
		{
			printf "%-29s   IN   %-7s %s\n" "${domain}" "${record}" "${target}"
		} >> "${NAMED_CUST_ZONE}/rpz"
	fi

	# Validate .conf file
	if ! output="$( named-checkconf "${NAMED_CUST_CONF}/rpz.conf" 2>&1 )"; then
		log "err" "Configuration failed." "${debug_level}"
		if [ -n "${output}" ]; then
			echo "${output}"
		fi
		log_file "${NAMED_CUST_CONF}/rpz.conf"
		exit 1
	elif [ "${debug_level}" -gt "1" ]; then
		if [ -n "${output}" ]; then
			echo "${output}"
		fi
	fi
	# Validate zone file
	if ! output="$( named-checkzone "rpz" "${NAMED_CUST_ZONE}/rpz" 2>&1 )"; then
		log "err" "Configuration failed." "${debug_level}"
		if [ -n "${output}" ]; then
			echo "${output}"
		fi
		log_file "${NAMED_CUST_CONF}/rpz.conf"
		log_file "${NAMED_CUST_ZONE}/rpz"
		exit 1
	elif [ "${debug_level}" -gt "1" ]; then
		if [ -n "${output}" ]; then
			echo "${output}"
		fi
	fi
}



####################################################################################################
###
### (4/6) BOOTSTRAP
###
####################################################################################################

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
		fi
	fi
else
	DEBUG_ENTRYPOINT="${DEFAULT_DEBUG_ENTRYPOINT}"
fi
log "info" "Debug level: ${DEBUG_ENTRYPOINT}" "${DEBUG_ENTRYPOINT}"



####################################################################################################
###
### (5/6) ENTRYPOINT (DEFAULTS)
###
####################################################################################################

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

		# Output configuration file
		log_file "${NAMED_LOG_CONF}"
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



####################################################################################################
###
### (6/6) ENTRYPOINT (ZONES)
###
####################################################################################################

REV_ZONES=""
FWD_ZONES=""

###
### Add Reverse DNS
###
if printenv DNS_PTR >/dev/null 2>&1; then
	while read -r line; do
		line="$( echo "${line}" | xargs -0 )"
		if [ -z "${line}" ]; then
			continue  # For leading or trailing comma in DNS_PTR variable
		fi
		addr="$( echo "${line}" | awk -F '=' '{print $1}' | xargs -0 )"
		name="$( echo "${line}" | awk -F '=' '{print $2}' | xargs -0 )"

		# Extract IP address octets
		o1="$( echo "${addr}" | awk -F '.' '{print $1}' )"
		o2="$( echo "${addr}" | awk -F '.' '{print $2}' )"
		o3="$( echo "${addr}" | awk -F '.' '{print $3}' )"
		o4="$( echo "${addr}" | awk -F '.' '{print $4}' )"
		zone="${o3}.${o2}.${o1}.in-addr.arpa"
		ptr="${o4}.${o3}.${o2}.${o1}.in-addr.arpa"

		# Append zones and get unique ones by newline separated
		REV_ZONES="$( echo "${REV_ZONES}"$'\n'"${zone}" | grep -vE '^$' | sort -u )"

		log "info" "Adding PTR Record: ${addr} -> ${name}" "${DEBUG_ENTRYPOINT}"
		add_rev_zone \
			"${addr}" \
			"${name}" \
			"${zone}" \
			"${ptr}" \
			"${TTL_TIME}" \
			"${REFRESH_TIME}" \
			"${RETRY_TIME}" \
			"${EXPIRY_TIME}" \
			"${MAX_CACHE_TIME}" \
			"${DEBUG_ENTRYPOINT}"
	done <<< "${DNS_PTR//,/$'\n'}"
else
	log "info" "Not adding any PTR records" "${DEBUG_ENTRYPOINT}"
fi


###
### Build forward zones (A Record)
###
if printenv DNS_A >/dev/null 2>&1; then
	while read -r line; do
		line="$( echo "${line}" | xargs -0 )"
		if [ -z "${line}" ]; then
			continue  # For leading or trailing comma in DNS_A variable
		fi
		name="$( echo "${line}" | awk -F '=' '{print $1}' | xargs -0 )"
		addr="$( echo "${line}" | awk -F '=' '{print $2}' | xargs -0 )"

		# Only a single zone used for forward zones (response policy zone)
		FWD_ZONES="rpz"

		log "info" "Adding A Record: ${name} -> ${addr}" "${DEBUG_ENTRYPOINT}"
		add_fwd_zone \
			"${name}" \
			"A" \
			"${addr}" \
			"${TTL_TIME}" \
			"${REFRESH_TIME}" \
			"${RETRY_TIME}" \
			"${EXPIRY_TIME}" \
			"${MAX_CACHE_TIME}" \
			"${DEBUG_ENTRYPOINT}"
	done <<< "${DNS_A//,/$'\n'}"
else
	log "info" "Not adding any A records" "${DEBUG_ENTRYPOINT}"
fi


###
### Build forward zones (CNAME Record)
###
if printenv DNS_CNAME >/dev/null 2>&1; then
	while read -r line; do
		line="$( echo "${line}" | xargs -0 )"
		if [ -z "${line}" ]; then
			continue  # For leading or trailing comma in DNS_CNAME variable
		fi
		name="$( echo "${line}" | awk -F '=' '{print $1}' | xargs -0 )"
		addr="$( echo "${line}" | awk -F '=' '{print $2}' | xargs -0 )"

		# Only a single zone used for forward zones (response policy zone)
		FWD_ZONES="rpz"

		log "info" "Adding CNAME Record: ${name} -> ${addr}" "${DEBUG_ENTRYPOINT}"
		add_fwd_zone \
			"${name}" \
			"CNAME" \
			"${addr}." \
			"${TTL_TIME}" \
			"${REFRESH_TIME}" \
			"${RETRY_TIME}" \
			"${EXPIRY_TIME}" \
			"${MAX_CACHE_TIME}" \
			"${DEBUG_ENTRYPOINT}"
	done <<< "${DNS_CNAME//,/$'\n'}"
else
	log "info" "Not adding any CNAME records" "${DEBUG_ENTRYPOINT}"
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
	while read -r ip ; do
		ip="$( echo "${ip}" | xargs -0 )"

		if ! is_ipv4_addr_or_ipv4_cidr "${ip}" && ! is_address_match_list "${ip}"; then
			log "err" "ALLOW_QUERY error: not a valid IPv4 address with optional mask: ${ip}" "${DEBUG_ENTRYPOINT}"
			exit 1
		fi

		if [ -z "${_allow_query_block}" ]; then
			_allow_query_block="        ${ip};"
		else
			_allow_query_block="${_allow_query_block}\n        ${ip};"
		fi
	done <<< "$( printenv ALLOW_QUERY | sed 's/,/\n/g' )"


	if [ -z "${_allow_query_block}" ]; then
		log "err" "ALLOW_QUERY error: variable specified, but no IP addresses found." "${DEBUG_ENTRYPOINT}"
		exit 1
	fi
	# shellcheck disable=SC2153
	log "info" "Adding custom allow-query options: ${ALLOW_QUERY}" "${DEBUG_ENTRYPOINT}"
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
	while read -r ip ; do
		ip="$( echo "${ip}" | xargs -0 )"

		if ! is_ipv4_addr_or_ipv4_cidr "${ip}" && ! is_address_match_list "${ip}"; then
			log "err" "ALLOW_RECURSION error: not a valid IPv4 address with optional mask: ${ip}" "${DEBUG_ENTRYPOINT}"
			exit 1
		fi

		if [ -z "${_allow_recursion_block}" ]; then
			_allow_recursion_block="        ${ip};"
		else
			_allow_recursion_block="${_allow_recursion_block}\n        ${ip};"
		fi
	done <<< "$( printenv ALLOW_RECURSION | sed 's/,/\n/g' )"


	if [ -z "${_allow_recursion_block}" ]; then
		log "err" "ALLOW_RECURSION error: variable specified, but no IP addresses found." "${DEBUG_ENTRYPOINT}"
		exit 1
	fi
	# shellcheck disable=SC2153
	log "info" "Adding custom allow-recursion options: ${ALLOW_RECURSION}" "${DEBUG_ENTRYPOINT}"
fi


###
### DNSSEC validation
###
if printenv DNSSEC_VALIDATE >/dev/null 2>&1; then
	DNSSEC_VALIDATE="$( printenv DNSSEC_VALIDATE )"
	if [ "${DNSSEC_VALIDATE}" = "auto" ]; then
		DNSSEC_VALIDATE="auto"
	elif [ "${DNSSEC_VALIDATE}" = "yes" ]; then
		DNSSEC_VALIDATE="yes"
	elif [ "${DNSSEC_VALIDATE}" = "no" ]; then
		DNSSEC_VALIDATE="no"
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

	add_options \
		"${NAMED_OPT_CONF}" \
		"${DNSSEC_VALIDATE}" \
		"" \
		"${_allow_query_block}" \
		"${_allow_recursion_block}" \
		"${FWD_ZONES}"
else

	# To be pupulated
	_forwarders_block=""

	# Transform into newline separated forwards and loop over:
	#   x.x.x.x\n
	#   y.y.y.y\n
	while read -r ip ; do
		ip="$( echo "${ip}" | xargs -0 )"

		if ! is_ip4_addr "${ip}"; then
			log "err" "DNS_FORWARDER error: not a valid IP address: ${ip}" "${DEBUG_ENTRYPOINT}"
			exit 1
		fi

		if [ -z "${_forwarders_block}" ]; then
			_forwarders_block="        ${ip};"
		else
			_forwarders_block="${_forwarders_block}\n        ${ip};"
		fi
	done <<< "$( printenv DNS_FORWARDER | sed 's/,/\n/g' )"

	if [ -z "${_forwarders_block}" ]; then
		log "err" "DNS_FORWARDER error: variable specified, but no IP addresses found." "${DEBUG_ENTRYPOINT}"
		exit 1
	fi

	log "info" "Adding custom DNS forwarder: ${DNS_FORWARDER}" "${DEBUG_ENTRYPOINT}"
	add_options \
		"${NAMED_OPT_CONF}" \
		"${DNSSEC_VALIDATE}" \
		"${_forwarders_block}" \
		"${_allow_query_block}" \
		"${_allow_recursion_block}" \
		"${FWD_ZONES}"
fi


###
### Log configured zones
###
while IFS= read -r line; do
	if [ -n "${line}" ]; then
		log_file "${NAMED_CUST_CONF}/${line}.conf"
		log_file "${NAMED_CUST_ZONE}/${line}"
	fi
done <<< "${REV_ZONES}"
while IFS= read -r line; do
	if [ -n "${line}" ]; then
		log_file "${NAMED_CUST_CONF}/${line}.conf"
		log_file "${NAMED_CUST_ZONE}/${line}"
	fi
done <<< "${FWD_ZONES}"


###
### Start
###
log "info" "Starting $( named -V | grep -oiE '^BIND[[:space:]]+[0-9.]+' )" "${DEBUG_ENTRYPOINT}"
named-checkconf "${NAMED_CONF}"
exec /usr/sbin/named -4 -c /etc/bind/named.conf -u bind -f
