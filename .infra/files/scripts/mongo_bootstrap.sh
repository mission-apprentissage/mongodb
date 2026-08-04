#!/usr/bin/env bash

set -euo pipefail

mongosh "mongodb://localhost:27017/?directConnection=true" \
  --tls \
  --tlsCAFile /mnt/data/mongodb-ca.pem \
  --tlsAllowInvalidHostnames \
  "$@"
