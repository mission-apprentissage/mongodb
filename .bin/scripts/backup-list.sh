#!/usr/bin/env bash

set -euo pipefail

PREFIX=${1:?"Merci de préciser le chemin S3 (utiliser la commande 'backup:bucket:list' pour obtenir la liste des buckets)"}

"${SCRIPTS_DIR}/s3.sh" ls --human-readable "s3://${PREFIX}"

