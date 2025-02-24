#!/usr/bin/env bash

set -euo pipefail

function Help() {
   # Display Help
   echo "Commands"
   echo "  bin:setup                                               Installs ${PRODUCT_NAME} binary with zsh completion on system"
   echo "  deploy:initial:node <env>                               Création d'un nouveau cluster <env>"
   echo "  deploy:update:node <env>                                Mise à jour du noeud <env>"
   echo "  deploy:extra:node <env>                                 Ajout du noeud à un cluster existant <env>"
   echo "  deploy:remove:node <env>                                Suppression du noeud <env>"
   echo "  vault:init                                              Fetch initial vault-password from template-apprentissage"
   echo "  vault:edit                                              Edit vault file"
   echo "  vault:password                                          Show vault password"
   echo "  deploy:log:decrypt                                      Decrypt Github ansible logs"
   echo "  deploy:log:encrypt                                      Encrypt Github ansible logs"
   echo "  deploy:log:decrypt                                      Decrypt Github ansible logs"
   echo "  backup:bucket:list                                      Get the list of all available archives buckets for select"
   echo "  backup:list                                             List all available backups from a bucket"
   echo "  backup:download                                         Download database archive and resolve the GPG file to be exploited by a mongorestore command"
   echo "  product:validate:env                                    Validate products envs by listing there IPs using ansible"
   echo 
   echo
}

function bin:setup() {
  sudo ln -fs "${ROOT_DIR}/.bin/mna" "/usr/local/bin/mna-${PRODUCT_NAME}"

  sudo mkdir -p /usr/local/share/zsh/site-functions
  sudo ln -fs "${ROOT_DIR}/.bin/zsh-completion" "/usr/local/share/zsh/site-functions/_${PRODUCT_NAME}"
  sudo rm -f ~/.zcompdump*
}

function deploy:update:node() {
  product:validate:env "$1"
  "${SCRIPT_DIR}/deploy-app.sh" "$@" --extra-vars "context=update"
}

function deploy:initial:node() {
  "${SCRIPT_DIR}/deploy-app.sh" "$@" --extra-vars "context=new-cluster"
}

function deploy:extra:node() {
  "${SCRIPT_DIR}/deploy-app.sh" "$@" --extra-vars "context=new-member"
}

function deploy:remove:node() {
  "${SCRIPT_DIR}/remove-node.sh" "$@"
}

function vault:init() {
  # Ensure Op is connected
  op --account mission-apprentissage account get > /dev/null
  op --account mission-apprentissage document get ".vault-password-tmpl" --vault "mna-vault-passwords-common" > "${ROOT_DIR}/.infra/vault/.vault-password.gpg"
}

function vault:edit() {
  editor=${EDITOR:-'code -w'}
  EDITOR=$editor "${SCRIPT_DIR}/edit-vault.sh" "$@"
}

function vault:password() {
  "${SCRIPT_DIR}/get-vault-password-client.sh" "$@"
}

function deploy:log:encrypt() {
  (cd "$ROOT_DIR" && "${SCRIPT_DIR}/deploy-log-encrypt.sh" "$@")
}

function deploy:log:decrypt() {
  (cd "$ROOT_DIR" && "${SCRIPT_DIR}/deploy-log-decrypt.sh" "$@")
}

function backup:bucket:list() {
  "${SCRIPT_DIR}/s3.sh" ls --human-readable
}

function backup:list() {
  PREFIX=${1:?"Merci de préciser le path S3 (utiliser la commande 'backup:bucket:list' pour obtenir la liste des buckets)"}
  "${SCRIPT_DIR}/s3.sh" ls --human-readable "s3://${PREFIX}"
}

function backup:download() {
  FILENAME=${1:?"Merci de préciser le fichier"}
  mkdir -p "${ROOT_DIR}/tmp"
  "${SCRIPT_DIR}/s3.sh" cp "s3://${FILENAME}" "${ROOT_DIR}/tmp/${FILENAME}"
  "${SCRIPT_DIR}/decrypt.sh" "${ROOT_DIR}/tmp/${FILENAME}" > "${ROOT_DIR}/tmp/${FILENAME}.secret"
}

function product:validate:env() {
  # If we're able to get ip then we're good
  local env_ip=$(ANSIBLE_CONFIG="${ROOT_DIR}/.infra/ansible/ansible.cfg" ansible-inventory --list -l "$1" | jq -r ".${1}.hosts[0]")

  echo $env_ip
  if [[ "$env_ip" == "null" ]]; then
    if [[ -z "${CI:-}" ]]; then
      exit 1;
    else
      # If we are in CI just exit 0 to allow batch
      exit 0;
    fi;
  fi;
}