#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### Variables
###

IFS=$'\n'

# Current directory
CWD="$( dirname "${0}" )"
IMAGE="${1}"
NAME="${2}"
VERSION="${3}"
TAG="${4}"
ARCH="${5}"
DEBUG="${6}"

declare -a TESTS=()




###
### Run tests
###

# Get all [0-9]+.sh test files
FILES="$( find "${CWD}" -regex "${CWD}/[0-9].+\.sh" | sort -u )"
for f in ${FILES}; do
	TESTS+=("${f}")
done

# Start a single test
if [ "${#}" -eq "3" ]; then
	sh -c "${TESTS[${2}]} ${IMAGE} ${NAME} ${VERSION} ${TAG} ${ARCH}"

# Run all tests
else
	for i in "${TESTS[@]}"; do
		echo "########################################################################################################################"
		echo "########################################################################################################################"
		echo "###"
		echo "### [${CWD}/${i}] ${IMAGE}:${TAG} ${NAME}-${VERSION} (${ARCH})"
		echo "###"
		echo "########################################################################################################################"
		echo "########################################################################################################################"
		if ! sh -c "${i} ${IMAGE} ${NAME} ${VERSION} ${TAG} ${ARCH} ${DEBUG}"; then
			if ! sh -c "${i} ${IMAGE} ${NAME} ${VERSION} ${TAG} ${ARCH} ${DEBUG}"; then
				if ! sh -c "${i} ${IMAGE} ${NAME} ${VERSION} ${TAG} ${ARCH} ${DEBUG}"; then
					echo "Failed after 3 repeats"
					exit 1
				fi
			fi
		fi
		printf "\\n\\n"
	done
fi
