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
NAME="$( grep 'image=".*"' "${CWD}/Dockerfile" | sed 's/^[[:space:]]*//g' | awk -F'"' '{print $2}' )"
DATE="$( date '+%Y-%m-%d' )"


###
### Build
###

# Build Docker
run "docker build --no-cache -t cytopia/${NAME} ${CWD}"

# Update build date
run "sed -i'' 's/<small>\*\*Latest\sbuild.*/<small>**Latest build:** ${DATE}<\/small>/g' ${CWD}/README.md"
run "sed -i'' 's/build-date=\".*\"/build-date=\"${DATE}\"/g' ${CWD}/Dockerfile"


###
### Test
###

docker run -d --rm --name my_tmp_${NAME} -t cytopia/${NAME}
BIND_VERSION="$( docker exec my_tmp_${NAME}  named -V | grep -oiE '^BIND[[:space:]]+[0-9.]+' )"
docker stop "$(docker ps | grep "my_tmp_${NAME}" | awk '{print $1}')"

echo "${BIND_VERSION}"

sed -i'' '/##[[:space:]]Version/q' "${CWD}/README.md"
echo "" >> "${CWD}/README.md"
echo "${BIND_VERSION}" >> "${CWD}/README.md"
