#!/usr/bin/env bash

set -euo pipefail

function Help() {
   # Display Help
   echo "Commands"
   echo "  bin:setup                                               Installs ${PRODUCT_NAME} binary with zsh completion on system"
   echo "  deploy <env> --user <your_username>                                           Deploy application to <env>"
   echo "  vault:init                                                                    Fetch initial vault-password from template-apprentissage"
   echo "  vault:edit                                                                    Edit vault file"
   echo "  vault:password                                                                Show vault password"
   echo "  deploy:log:encrypt                         Encrypt Github ansible logs"
   echo "  deploy:log:dencrypt                        Decrypt Github ansible logs"
   echo 
   echo
}

function bin:setup() {
  sudo ln -fs "${ROOT_DIR}/.bin/mna" "/usr/local/bin/mna-${PRODUCT_NAME}"

  sudo mkdir -p /usr/local/share/zsh/site-functions
  sudo ln -fs "${ROOT_DIR}/.bin/zsh-completion" "/usr/local/share/zsh/site-functions/_${PRODUCT_NAME}"
  sudo rm -f ~/.zcompdump*
}

function deploy() {
  "${SCRIPT_DIR}/deploy-app.sh" "$@"
}

function vault:init() {
  # Ensure Op is connected
  op account get > /dev/null
  op document get ".vault-password-tmpl" --vault "mna-vault-passwords-common" > "${ROOT_DIR}/.infra/vault/.vault-password.gpg"
}

function vault:edit() {
  editor=${EDITOR:-'code -w'}
  EDITOR=$editor "${SCRIPT_DIR}/edit-vault.sh" "$@"
}

function vault:password() {
  "${SCRIPT_DIR}/get-vault-password-client.sh" "$@"
}

function deploy:log:encrypt() {
  "${SCRIPT_DIR}/deploy-log-encrypt.sh" "$@"
}

function deploy:log:decrypt() {
  "${SCRIPT_DIR}/deploy-log-decrypt.sh" "$@"
}

