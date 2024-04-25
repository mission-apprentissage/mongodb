#!/usr/bin/env bash
set -euo pipefail

readonly ENV_FILTER=${1:?"Merci de préciser le nom du noeud principal"}
shift

function deploy() {
  echo "Vous etes sur le point de supprimer le noeud ${ENV_FILTER}, voulez-vous continuer ?"
  read -p "Confirmez-vous la suppression du noeud ${ENV_FILTER} ? (y/N) " -n 1 -r

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Suppression annulée"
    exit 1
  fi

  "${ROOT_DIR}/.bin/scripts/run-playbook.sh" "remove_node.yml" "$ENV_FILTER" "$@"
}

deploy "$@"
