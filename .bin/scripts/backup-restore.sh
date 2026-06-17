#!/usr/bin/env bash

set -euo pipefail

FILENAME=${1:?"Merci de préciser le fichier"}
URI=${2:?"Merci de préciser l'uri de MongoDB de destination"}

BIN_DIR="$(dirname -- "$( readlink -f -- "$0"; )")"
ROOT_DIR="${BIN_DIR}/../.."

echo "Êtes-vous sûr de vouloir restaurer la base de données ? (y/n)"
read -r -n 1 -s answer

if [ "$answer" != "y" ]; then
  echo "Annulation de la restauration"
  exit 1
fi

cleanup() {
  rm -rf "${ROOT_DIR}/tmp/" 
}
trap cleanup EXIT

${ROOT_DIR}/.bin/mna backup:download "$FILENAME"

cat "${ROOT_DIR}/tmp/${FILENAME}.secret" \
  | docker run --rm -i \
      --network host mongo:8 mongorestore \
      --gzip \
      --drop \
      --archive \
      --uri="$URI"
