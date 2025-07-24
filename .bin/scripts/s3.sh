#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${ANSIBLE_VAULT_PASSWORD_FILE:-}" ]]; then
  ansible_extra_opts+=("--vault-password-file" "${SCRIPT_DIR}/get-vault-password-client.sh")
else
  echo "Récupération de la passphrase depuis l'environnement variable ANSIBLE_VAULT_PASSWORD_FILE" 
fi

delete_cleartext() {
  if [ -f "${ROOT_DIR}/.vault_pwd.txt" ]; then
    shred -f -n 10 -u "${ROOT_DIR}/.vault_pwd.txt"
  fi
}
trap delete_cleartext EXIT

readonly VAULT_FILE="${ROOT_DIR}/.infra/vault/vault.yml"

ansible-vault view "${ansible_extra_opts[@]}" "$VAULT_FILE" > "${ROOT_DIR}/.vault_pwd.txt"

OVH_S3_USER=$(cat "${ROOT_DIR}/.vault_pwd.txt" | yq '.vault.OVH_S3_USER')
OVH_S3_API_KEY=$(cat "${ROOT_DIR}/.vault_pwd.txt" | yq '.vault.OVH_S3_API_KEY')
OVH_S3_API_SECRET=$(cat "${ROOT_DIR}/.vault_pwd.txt" | yq '.vault.OVH_S3_API_SECRET')
OVH_S3_BUCKET=$(cat "${ROOT_DIR}/.vault_pwd.txt" | yq '.vault.OVH_S3_BUCKET')
OVH_S3_ENDPOINT=$(cat "${ROOT_DIR}/.vault_pwd.txt" | yq '.vault.OVH_S3_ENDPOINT')
OVH_S3_REGION=$(cat "${ROOT_DIR}/.vault_pwd.txt" | yq '.vault.OVH_S3_REGION')

export AWS_ACCESS_KEY_ID="${OVH_S3_API_KEY}"
export AWS_SECRET_ACCESS_KEY="${OVH_S3_API_SECRET}" 
export AWS_DEFAULT_REGION="${OVH_S3_REGION}" 
export AWS_ENDPOINT_URL="${OVH_S3_ENDPOINT}"

aws s3 "$@"
