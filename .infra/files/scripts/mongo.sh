#!/usr/bin/env bash

set -euo pipefail

mongosh "mongodb://__system:{{vault[env_type].KEYFILE}}@{{dns_name}}:27017/?authSource=local&directConnection=true&tls=true" "$@"
