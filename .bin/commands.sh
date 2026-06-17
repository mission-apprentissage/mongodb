#!/usr/bin/env bash

set -euo pipefail

SUBMODULE_PATH="${ROOT_DIR}/.bin/shared"

if [[ ! -f "$SUBMODULE_PATH/.git" ]] && [[ ! -d "$SUBMODULE_PATH/.git" ]]; then

  echo "Initialisation du sous-module : $SUBMODULE_PATH"
  git submodule update --init -- "$SUBMODULE_PATH"

else

  expected=$(git ls-files --stage -- "$SUBMODULE_PATH" | awk '{print $2}')
  current=$(git -C "$SUBMODULE_PATH" rev-parse HEAD)

  if [[ "$expected" != "$current" ]]; then

    echo "Mise à jour du sous-module :"
    echo "$current → $expected"
    git submodule update -- "$SUBMODULE_PATH"

  fi

fi

. "${ROOT_DIR}/.bin/shared/commands.sh"

################################################################################
# Shared commands
################################################################################

_register "app:deploy:log:encrypt"
_register "app:deploy:log:decrypt"
_register "dev:dependencies:check"
_register "dev:setup"
_register "vault:edit"

################################################################################
# Local commands
################################################################################

_local_app_deploy_cluster_init__help="Init a new cluster"
_register "app:deploy:cluster:init" "_local_app_deploy_cluster_init"

function _local_app_deploy_cluster_init() {
  "${SCRIPTS_SHARED_DIR}/app-deploy.sh" "$@" --extra-vars "context=new-cluster"
}

_local_app_deploy_cluster_node_update__help="Update cluster"
_register "app:deploy:cluster:node:update" "_local_app_deploy_cluster_node_update"

function _local_app_deploy_cluster_node_update() {
  "${scripts_dir}/app-deploy-cluster-node-update.sh" "$@"
}

_local_app_deploy_cluster_node_add__help="Add node to existing cluster"
_register "app:deploy:cluster:node:add" "_local_app_deploy_cluster_node_add"

function _local_app_deploy_cluster_node_add() {
  "${SCRIPTS_SHARED_DIR}/app-deploy.sh" "$@" --extra-vars "context=new-member"
}

_local_app_deploy_cluster_node_remove__help="Remove node from existing cluster"
_register "app:deploy:cluster:node:remove" "_local_app_deploy_cluster_node_remove"

function _local_app_deploy_cluster_node_remove() {
  "${SCRIPTS_DIR}/app-deploy-cluster-node-remove.sh" "$@"
}

_local_backup_bucket_list__help="List S3 buckets"
_register "backup:bucket:list" "_local_backup_bucket_list"

function _local_backup_bucket_list() {
  "${SCRIPTS_DIR}/s3.sh" ls --human-readable
}

_local_backup_list__help="List S3 files in bucket"
_register "backup:list" "_local_backup_list"

function _local_backup_list() {
  "${SCRIPTS_DIR}/backup-list.sh" "$@"
}

_local_backup_download__help="Download S3 file and decrypt it"
_register "backup:download" "_local_backup_download"

function _local_backup_download() {
  "${SCRIPTS_DIR}/backup-download.sh" "$@"
}

_local_backup_restore__help="Restore S3 file to MongoDB"
_register "backup:restore" "_local_backup_restore"

function _local_backup_restore() {
  "${SCRIPTS_DIR}/backup-restore.sh" "$@"
}

