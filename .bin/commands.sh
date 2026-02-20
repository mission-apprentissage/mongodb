#!/usr/bin/env bash

set -euo pipefail

if [ ! -f "${ROOT_DIR}/.bin/shared/commands.sh" ]; then

  echo "Mise à jour du sous-module mna-shared-bin"

  git submodule update --init "${ROOT_DIR}/.bin/shared"

fi

. "${ROOT_DIR}/.bin/shared/commands.sh"

unset _meta_help["app:deploy"]
unset app:deploy
unset _meta_help["seed:update"]
unset seed:update
unset _meta_help["seed:apply"]
unset seed:apply
unset _meta_help["docker:login"]
unset docker:login

################################################################################
# Non-shared commands
################################################################################

_meta_help["app:deploy:cluster:init"]="Init a new cluster"

function app:deploy:cluster:init() {
  "${SCRIPT_SHARED_DIR}/app-deploy.sh" "$@" --extra-vars "context=new-cluster"
}

_meta_help["app:deploy:cluster:node:update"]="Update cluster"

function app:deploy:cluster:node:update() {
  "${SCRIPT_DIR}/product-validate-env.sh" "$1"
  "${SCRIPT_SHARED_DIR}/app-deploy.sh" "$@" --extra-vars "context=update"
}

_meta_help["app:deploy:cluster:node:add"]="Add node to existing cluster"

function app:deploy:cluster:node:add() {
  "${SCRIPT_SHARED_DIR}/app-deploy.sh" "$@" --extra-vars "context=new-member"
}

_meta_help["app:deploy:cluster:node:remove"]="Delete node from cluster"

function app:deploy:cluster:node:remove() {
  "${SCRIPT_SHARED_DIR}/app:deploy:node-remove.sh" "$@"
}

_meta_help["backup:bucket:list"]="List S3 buckets"

function backup:bucket:list() {
  "${SCRIPT_DIR}/s3.sh" ls --human-readable
}

_meta_help["backup:list"]="List S3 files in bucket"

function backup:list() {
  "${SCRIPT_DIR}/backup-list.sh" "$@"
}

_meta_help["backup:download"]="Download S3 file and decrypt it"

function backup:download() {
  "${SCRIPT_DIR}/backup-download.sh" "$@"
}

_meta_help["backup:restore"]="Restore S3 file to MongoDB"

function backup:restore() {
  "${SCRIPT_DIR}/backup-restore.sh" "$@"
}

