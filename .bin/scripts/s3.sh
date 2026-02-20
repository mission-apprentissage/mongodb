#!/usr/bin/env bash

set -euo pipefail

readonly OVH_S3_USER=$(sops --decrypt --extract '["OVH_S3_USER"]' .infra/env.global.yml)
readonly OVH_S3_API_KEY=$(sops --decrypt --extract '["OVH_S3_API_KEY"]' .infra/env.global.yml)
readonly OVH_S3_API_SECRET=$(sops --decrypt --extract '["OVH_S3_API_SECRET"]' .infra/env.global.yml)
readonly OVH_S3_BUCKET=$(sops --decrypt --extract '["OVH_S3_BUCKET"]' .infra/env.global.yml)
readonly OVH_S3_ENDPOINT=$(sops --decrypt --extract '["OVH_S3_ENDPOINT"]' .infra/env.global.yml)
readonly OVH_S3_REGION=$(sops --decrypt --extract '["OVH_S3_REGION"]' .infra/env.global.yml)

export AWS_ACCESS_KEY_ID="${OVH_S3_API_KEY}"
export AWS_SECRET_ACCESS_KEY="${OVH_S3_API_SECRET}" 
export AWS_DEFAULT_REGION="${OVH_S3_REGION}" 
export AWS_ENDPOINT_URL="${OVH_S3_ENDPOINT}"

aws s3 "$@"
