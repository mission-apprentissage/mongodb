#!/usr/bin/env bash

set -euo pipefail

FILENAME=${1:?"Merci de préciser le fichier"}

mkdir -p "${ROOT_DIR}/tmp"

"${SCRIPT_DIR}/s3.sh" cp "s3://${FILENAME}" "${ROOT_DIR}/tmp/${FILENAME}"

"${SCRIPT_DIR}/decrypt.sh" "${ROOT_DIR}/tmp/${FILENAME}" > "${ROOT_DIR}/tmp/${FILENAME}.secret"

