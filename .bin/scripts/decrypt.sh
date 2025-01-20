#!/usr/bin/env bash

set -euo pipefail

FILE=${1:?"Veuillez renseigner le nom du fichier à décrypter"}

if [[ -z "${ANSIBLE_VAULT_PASSWORD_FILE:-}" ]]; then
  ansible_extra_opts+=("--vault-password-file" "${SCRIPT_DIR}/get-vault-password-client.sh")
else
  echo "Récupération de la passphrase depuis l'environnement variable ANSIBLE_VAULT_PASSWORD_FILE" 
fi

readonly PASSPHRASE="$ROOT_DIR/.bin/SEED_PASSPHRASE.txt"
readonly VAULT_FILE="${ROOT_DIR}/.infra/vault/vault.yml"

delete_cleartext() {
  rm -f "$PASSPHRASE"
}

trap delete_cleartext EXIT

ansible-vault view "${ansible_extra_opts[@]}" "$VAULT_FILE" | yq '.vault.SEED_GPG_PASSPHRASE' > "$PASSPHRASE"

gpg -d --batch --passphrase-file "$PASSPHRASE" "$FILE"
