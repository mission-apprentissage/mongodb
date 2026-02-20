#!/usr/bin/env bash

set -euo pipefail

FILE=${1:?"Veuillez renseigner le nom du fichier à décrypter"}

readonly PASSPHRASE=$(sops --decrypt --extract '["SEED_GPG_PASSPHRASE"]' .infra/env.global.yml)

gpg -d --batch --passphrase-file "$PASSPHRASE" "$FILE"
