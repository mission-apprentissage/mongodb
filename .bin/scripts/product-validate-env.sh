#!/usr/bin/env bash

set -euo pipefail

readonly env_ip=$(ANSIBLE_CONFIG="${ROOT_DIR}/.infra/ansible/ansible.cfg" ansible-inventory --list -l "$1" | jq -r ".${1}.hosts[0]")

echo $env_ip

if [[ "$env_ip" == "null" ]]; then

  if [[ -z "${CI:-}" ]]; then
    exit 1
  else
    exit 0
  fi

fi
