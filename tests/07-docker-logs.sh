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

NAME="bind$( shuf -i 1000000000-2000000000 -n 1 )"
PORT="5300"


# DEBUG_ENTRYPOINT=2
run "docker run --rm --platform ${ARCH} --name ${NAME} -e DEBUG_ENTRYPOINT=2 -e 'EXTRA_HOSTS=www.devilbox=google.com' -e DOCKER_LOGS=1 -p ${PORT}:53/udp ${IMAGE}:${TAG} &"
run "sleep 5"
sanity_check "${NAME}"
run "dig @127.0.0.1 -p ${PORT} +short www.devilbox || true"
if ! run "docker logs ${NAME} 2>&1 | grep -E 'query:\s+www\.devilbox\s+IN'"; then
	docker logs "${NAME}" || true
	docker stop "${NAME}"
	exit 1
fi
run "docker stop ${NAME}"


# DEBUG_ENTRYPOINT=1
run "docker run --rm --platform ${ARCH} --name ${NAME} -e DEBUG_ENTRYPOINT=1 -e 'EXTRA_HOSTS=www.devilbox=google.com' -e DOCKER_LOGS=1 -p ${PORT}:53/udp ${IMAGE}:${TAG} &"
run "sleep 5"
sanity_check "${NAME}"
run "dig @127.0.0.1 -p ${PORT} +short www.devilbox || true"
if ! run "docker logs ${NAME} 2>&1 | grep -E 'query:\s+www\.devilbox\s+IN'"; then
	docker logs "${NAME}" || true
	docker stop "${NAME}"
	exit 1
fi
run "docker stop ${NAME}"


# DEBUG_ENTRYPOINT=0
run "docker run --rm --platform ${ARCH} --name ${NAME} -e DEBUG_ENTRYPOINT=0 -e 'EXTRA_HOSTS=www.devilbox=google.com' -e DOCKER_LOGS=1 -p ${PORT}:53/udp ${IMAGE}:${TAG} &"
run "sleep 5"
sanity_check "${NAME}"
run "dig @127.0.0.1 -p ${PORT} +short www.devilbox || true"
if ! run "docker logs ${NAME} 2>&1 | grep -E 'query:\s+www\.devilbox\s+IN'"; then
	docker logs "${NAME}" || true
	docker stop "${NAME}"
	exit 1
fi
run "docker stop ${NAME}"


# DEBUG_ENTRYPOINT=null
run "docker run --rm --platform ${ARCH} --name ${NAME} -e 'EXTRA_HOSTS=www.devilbox=google.com' -e DOCKER_LOGS=1 -p ${PORT}:53/udp ${IMAGE}:${TAG} &"
run "sleep 5"
sanity_check "${NAME}"
run "dig @127.0.0.1 -p ${PORT} +short www.devilbox || true"
if ! run "docker logs ${NAME} 2>&1 | grep -E 'query:\s+www\.devilbox\s+IN'"; then
	docker logs "${NAME}" || true
	docker stop "${NAME}"
	exit 1
fi
run "docker stop ${NAME}"
