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
PORT="5300"
WAIT=5
REPS=10


# DEBUG_ENTRYPOINT=2
run "docker run -d --rm --platform ${ARCH} --name ${NAME} -e DEBUG=${DEBUG} -e DEBUG_ENTRYPOINT=2 -e DOCKER_LOGS=1 -e 'EXTRA_HOSTS=www.devilbox=google.com' -p ${PORT}:53/udp ${IMAGE}:${TAG}"
run "sleep ${WAIT}"
sanity_check "${NAME}"
i=0
while ! run "dig @127.0.0.1 -p ${PORT} +short www.devilbox | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'"; do
	i=$(( i + 1 ))
	if [ "${i}" -gt "${REPS}" ]; then
		echo "FAILED: www.devilbox is not resolvable"
		run "dig @127.0.0.1 -p ${PORT} +short www.devilbox"
		run "docker logs ${NAME}"
		run "docker stop ${NAME}"
		echo "ABORT..."
		exit 1
	fi
	sleep 1
done
if [ "$( dig @127.0.0.1 -p ${PORT} +short t1.devilbox | wc -l )" != "0" ]; then
	run "docker stop ${NAME}"
	exit 1
fi
docker_stop "${NAME}"


# DEBUG_ENTRYPOINT=1
run "docker run -d --rm --platform ${ARCH} --name ${NAME} -e DEBUG=${DEBUG} -e DEBUG_ENTRYPOINT=1 -e DOCKER_LOGS=1 -e 'EXTRA_HOSTS=www.devilbox=google.com' -p ${PORT}:53/udp ${IMAGE}:${TAG}"
run "sleep ${WAIT}"
sanity_check "${NAME}"
i=0
while ! run "dig @127.0.0.1 -p ${PORT} +short www.devilbox | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'"; do
	i=$(( i + 1 ))
	if [ "${i}" -gt "${REPS}" ]; then
		echo "FAILED: www.devilbox is not resolvable"
		run "dig @127.0.0.1 -p ${PORT} +short www.devilbox"
		run "docker logs ${NAME}"
		run "docker stop ${NAME}"
		echo "ABORT..."
		exit 1
	fi
	sleep 1
done
if [ "$( dig @127.0.0.1 -p ${PORT} +short t1.devilbox | wc -l )" != "0" ]; then
	run "docker stop ${NAME}"
	exit 1
fi
docker_stop "${NAME}"


# DEBUG_ENTRYPOINT=0
run "docker run -d --rm --platform ${ARCH} --name ${NAME} -e DEBUG=${DEBUG} -e DEBUG_ENTRYPOINT=0 -e DOCKER_LOGS=1 -e 'EXTRA_HOSTS=www.devilbox=google.com' -p ${PORT}:53/udp ${IMAGE}:${TAG}"
run "sleep ${WAIT}"
sanity_check "${NAME}"
i=0
while ! run "dig @127.0.0.1 -p ${PORT} +short www.devilbox | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'"; do
	i=$(( i + 1 ))
	if [ "${i}" -gt "${REPS}" ]; then
		echo "FAILED: www.devilbox is not resolvable"
		run "dig @127.0.0.1 -p ${PORT} +short www.devilbox"
		run "docker logs ${NAME}"
		run "docker stop ${NAME}"
		echo "ABORT..."
		exit 1
	fi
	sleep 1
done
if [ "$( dig @127.0.0.1 -p ${PORT} +short t1.devilbox | wc -l )" != "0" ]; then
	run "docker stop ${NAME}"
	exit 1
fi
docker_stop "${NAME}"


# DEBUG_ENTRYPOINT=null
run "docker run -d --rm --platform ${ARCH} --name ${NAME} -e DEBUG=${DEBUG} -e DOCKER_LOGS=1 -e 'EXTRA_HOSTS=www.devilbox=google.com' -p ${PORT}:53/udp ${IMAGE}:${TAG}"
run "sleep ${WAIT}"
sanity_check "${NAME}"
i=0
while ! run "dig @127.0.0.1 -p ${PORT} +short www.devilbox | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'"; do
	i=$(( i + 1 ))
	if [ "${i}" -gt "${REPS}" ]; then
		echo "FAILED: www.devilbox is not resolvable"
		run "dig @127.0.0.1 -p ${PORT} +short www.devilbox"
		run "docker logs ${NAME}"
		run "docker stop ${NAME}"
		echo "ABORT..."
		exit 1
	fi
	sleep 1
done
if [ "$( dig @127.0.0.1 -p ${PORT} +short t1.devilbox | wc -l )" != "0" ]; then
	docker stop "${NAME}"
	exit 1
fi
docker_stop "${NAME}"
