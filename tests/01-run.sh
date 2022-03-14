#!/bin/sh

set -e
set -u

# Current directory
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck disable=SC1090
. "${CWD}/.lib.sh"

IMAGE="${1}"
#NAME="${2}"
#VERSION="${3}"
TAG="${4}"
ARCH="${5}"
DEBUG="${6}"

NAME="bind$( shuf -i 1000000000-2000000000 -n 1 )"


# DEBUG_ENTRYPOINT=2
run "docker run -d --rm --platform ${ARCH} --name ${NAME} -e DEBUG=${DEBUG} -e DEBUG_ENTRYPOINT=2 ${IMAGE}:${TAG}"
run "sleep 5"
sanity_check "${NAME}"
if ! run "docker exec ${NAME} named -V"; then
	run "docker stop ${NAME}"
	exit 1
fi
if ! run "docker exec ${NAME} named -V | grep -oiE '^BIND[[:space:]]+[0-9.]+'"; then
	run "docker stop ${NAME}"
	exit 1
fi
docker_stop "${NAME}"


# DEBUG_ENTRYPOINT=1
run "docker run -d --rm --platform ${ARCH} --name ${NAME} -e DEBUG=${DEBUG} -e DEBUG_ENTRYPOINT=1 ${IMAGE}:${TAG}"
run "sleep 5"
sanity_check "${NAME}"
if ! run "docker exec ${NAME} named -V"; then
	run "docker stop ${NAME}"
	exit 1
fi
if ! run "docker exec ${NAME} named -V | grep -oiE '^BIND[[:space:]]+[0-9.]+'"; then
	run "docker stop ${NAME}"
	exit 1
fi
docker_stop "${NAME}"


# DEBUG_ENTRYPOINT=0
run "docker run -d --rm --platform ${ARCH} --name ${NAME} -e DEBUG=${DEBUG} -e DEBUG_ENTRYPOINT=1 ${IMAGE}:${TAG}"
run "sleep 5"
sanity_check "${NAME}"
if ! run "docker exec ${NAME} named -V"; then
	run "docker stop ${NAME}"
	exit 1
fi
if ! run "docker exec ${NAME} named -V | grep -oiE '^BIND[[:space:]]+[0-9.]+'"; then
	run "docker stop ${NAME}"
	exit 1
fi
docker_stop "${NAME}"


# DEBUG_ENTRYPOINT=null
run "docker run -d --rm --platform ${ARCH} --name ${NAME} -e DEBUG=${DEBUG} ${IMAGE}:${TAG}"
run "sleep 5"
sanity_check "${NAME}"
if ! run "docker exec ${NAME} named -V"; then
	run "docker stop ${NAME}"
	exit 1
fi
if ! run "docker exec ${NAME} named -V | grep -oiE '^BIND[[:space:]]+[0-9.]+'"; then
	run "docker stop ${NAME}"
	exit 1
fi
docker_stop "${NAME}"
