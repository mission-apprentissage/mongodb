#!/usr/bin/env bash

set -euo pipefail

readonly ENV=${1:?"Merci de préciser le nom de l'environnement"}

BIN_DIR="$(dirname -- "$( readlink -f -- "$0"; )")"
ROOT_DIR="${BIN_DIR}/../.."
SCRIPT_SHARED_DIR="${ROOT_DIR}/.bin/shared/scripts"

readonly ENV_IP=$(ANSIBLE_CONFIG="${ROOT_DIR}/.infra/ansible/ansible.cfg" ansible-inventory --list -l "$1" 2>/dev/null | jq -r ".${1}.hosts[0]")

if [ "$ENV_IP" == "null" ]; then

  if [ -z "${CI:-}" ]; then
    exit 1
  fi

fi

"${SCRIPT_SHARED_DIR}/app-deploy.sh" "$@" --extra-vars "context=update"
