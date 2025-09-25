#!/usr/bin/env bash

set -euo pipefail

readonly ENV=${1:?"Merci de préciser l'environement"}
shift

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

S3_USER=$(cat "${ROOT_DIR}/.vault_pwd.txt" | yq -r ".vault.${ENV}.S3_USER")
S3_API_KEY=$(cat "${ROOT_DIR}/.vault_pwd.txt" | yq -r ".vault.${ENV}.S3_API_KEY")
S3_API_SECRET=$(cat "${ROOT_DIR}/.vault_pwd.txt" | yq -r ".vault.${ENV}.S3_API_SECRET")
S3_BUCKET=$(cat "${ROOT_DIR}/.vault_pwd.txt" | yq -r ".vault.${ENV}.S3_BUCKET")
S3_ENDPOINT=$(cat "${ROOT_DIR}/.vault_pwd.txt" | yq -r ".vault.${ENV}.S3_ENDPOINT")
S3_REGION=$(cat "${ROOT_DIR}/.vault_pwd.txt" | yq -r ".vault.${ENV}.S3_REGION")

export AWS_ACCESS_KEY_ID="${S3_API_KEY}"
export AWS_SECRET_ACCESS_KEY="${S3_API_SECRET}" 
export AWS_DEFAULT_REGION="${S3_REGION}" 
export AWS_ENDPOINT_URL="${S3_ENDPOINT}"

aws s3 "$@"
