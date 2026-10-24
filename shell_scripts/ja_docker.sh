#!/usr/bin/env bash
# Author: S M Jahangir Alam <jahangir2526@gmail.com>
# Last updated: 2026-10-24 +08
# Usage: ./shell_scripts/ja_docker.sh

set -euo pipefail

printf '%s\n' \
    'Assumptions / Pre-check:' \
    '1. The OCIR private/public repository created in OCI Console (e.g. repo-my-web-app).' \
    '2. The local Docker image is already built' \
    '   Example: docker buildx build --platform linux/amd64 -t my-web-app:v1 .' \
    ''

read_required() {
    local variable_name="$1"
    local prompt="$2"
    local default_value="${3-}"
    local value

    if [[ -n "$default_value" ]]; then
        prompt+=" [default: $default_value]"
    fi

    while true; do
        printf '%s: ' "$prompt" >&2
        if ! IFS= read -r value; then
            printf '\nInput ended before all required values were provided.\n' >&2
            exit 1
        fi
        value="${value:-$default_value}"
        if [[ "$value" =~ [^[:space:]] ]]; then
            printf -v "$variable_name" '%s' "$value"
            return
        fi
        printf 'A value is required. Please try again.\n' >&2
    done
}

read_required OCI_REGION_KEY 'Region key' 'iad'
read_required OCI_TENANCY_NAMESPACE 'OCI Tenancy namespace' 'apacaseanset01'
read_required OCI_IDENTITY_DOMAIN 'OCI Identity domain' 'OracleIdentityCloudService'
read_required OCI_USERNAME 'OCI Username' 'jahangir.alam@oracle.com'
read_required LOCAL_IMAGE_NAME 'Local image name (e.g. my-web-app)'
read_required LOCAL_IMAGE_TAG 'Local image tag (e.g. v1)'
read_required OCIR_REPO_NAME 'OCIR repository name' "repo-${LOCAL_IMAGE_NAME}"
read_required OCIR_REPO_TAG 'OCIR repository tag' "$LOCAL_IMAGE_TAG"

printf '\nRegion key: %s\nLocal image: %s\nTenancy namespace: %s\nOCIR repository: %s\nOCIR tag: %s\n' \
    "$OCI_REGION_KEY" "$LOCAL_IMAGE_NAME:$LOCAL_IMAGE_TAG" "$OCI_TENANCY_NAMESPACE" "$OCIR_REPO_NAME" "$OCIR_REPO_TAG"

OCIR_REGISTRY="${OCI_REGION_KEY}.ocir.io"
OCIR_IMAGE="${OCIR_REGISTRY}/${OCI_TENANCY_NAMESPACE}/${OCIR_REPO_NAME}:${OCIR_REPO_TAG}"
OCIR_LOGIN_USERNAME="${OCI_TENANCY_NAMESPACE}/${OCI_IDENTITY_DOMAIN}/${OCI_USERNAME}"

printf '\n#########Generating docker commands #########\n\n'

printf '========= Docker build image =========\n\n'
printf 'docker buildx build --platform linux/amd64 --provenance=false --sbom=false --load -t %q .\n\n' "$LOCAL_IMAGE_NAME:$LOCAL_IMAGE_TAG"

printf '========= Docker login =========\n\n'
printf 'docker login %q\n' "$OCIR_REGISTRY"
printf 'Username: %s\n' "$OCIR_LOGIN_USERNAME"
printf 'Password: <OCI Auth Token>\n\n'

printf '========= Docker tag / push =========\n\n'
printf 'docker tag %q %q\n' "$LOCAL_IMAGE_NAME:$LOCAL_IMAGE_TAG" "$OCIR_IMAGE"
printf 'docker push %q\n' "$OCIR_IMAGE"
