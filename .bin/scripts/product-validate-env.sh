#!/usr/bin/env bash

set -euo pipefail

readonly ENV=${1:?"Merci de préciser le nom de l'environnement"}

BIN_DIR="$(dirname -- "$( readlink -f -- "$0"; )")"
ROOT_DIR="${BIN_DIR}/../.."

readonly ENV_IP=$(ANSIBLE_CONFIG="${ROOT_DIR}/.infra/ansible/ansible.cfg" ansible-inventory --list -l "$1" 2>/dev/null | jq -r ".${1}.hosts[0]")

echo $ENV_IP

if [[ "$ENV_IP" == "null" ]]; then

  if [[ -z "${CI:-}" ]]; then
    exit 1
  else
    exit 0
  fi

fi
