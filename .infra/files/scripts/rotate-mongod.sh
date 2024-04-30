#!/usr/bin/env bash
set -euo pipefail

/opt/app/scripts/mongo_local.sh --eval "db.adminCommand( { logRotate: 1 } )"
