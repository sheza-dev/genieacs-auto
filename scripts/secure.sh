#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_command docker
load_env

require_non_placeholder BASE_DOMAIN "${BASE_DOMAIN}"
require_non_placeholder ACME_EMAIL "${ACME_EMAIL}"
require_non_placeholder MONGO_ROOT_PASSWORD "${MONGO_ROOT_PASSWORD}"
require_non_placeholder MONGO_APP_PASSWORD "${MONGO_APP_PASSWORD}"
require_non_placeholder GENIEACS_UI_JWT_SECRET "${GENIEACS_UI_JWT_SECRET}"

ensure_dir "${REPO_ROOT}/data"
ensure_dir "${REPO_ROOT}/${GENIEACS_EXT_DIR#./}"
ensure_dir "${REPO_ROOT}/${GENIEACS_LOG_DIR#./}"
ensure_dir "${REPO_ROOT}/${TRAEFIK_DATA_DIR#./}"
ensure_dir "${REPO_ROOT}/${MONGO_DATA_DIR#./}"
ensure_dir "${REPO_ROOT}/${MONGO_CONFIGDB_DIR#./}"

if [[ ! -f "${REPO_ROOT}/${TRAEFIK_DATA_DIR#./}/acme.json" ]]; then
  : > "${REPO_ROOT}/${TRAEFIK_DATA_DIR#./}/acme.json"
fi

chmod 700 "${REPO_ROOT}/${TRAEFIK_DATA_DIR#./}"
chmod 600 "${ENV_FILE}" "${REPO_ROOT}/${TRAEFIK_DATA_DIR#./}/acme.json"
chmod 755 "${REPO_ROOT}/scripts"/*.sh
chmod 755 "${REPO_ROOT}/scripts/lib/common.sh"

if command -v ufw >/dev/null 2>&1 && [[ "${APPLY_UFW:-false}" == "true" ]]; then
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  sudo ufw --force enable
fi

(cd "${REPO_ROOT}" && docker compose config >/dev/null)
log "Security baseline prepared successfully."
