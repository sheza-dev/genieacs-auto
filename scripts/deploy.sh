#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_command docker
load_env
"${SCRIPT_DIR}/secure.sh"

log "Pulling container images"
(cd "${REPO_ROOT}" && docker compose pull)

log "Starting production stack"
(cd "${REPO_ROOT}" && docker compose up -d --remove-orphans)

"${SCRIPT_DIR}/confirm.sh"
