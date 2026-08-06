#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_command openssl

BASE_DOMAIN_INPUT="${1:-${BASE_DOMAIN:-}}"
ACME_EMAIL_INPUT="${2:-${ACME_EMAIL:-}}"
ACME_PROVIDER_INPUT="${3:-${ACME_DNS_PROVIDER:-cloudflare}}"

if [[ -f "${ENV_FILE}" ]]; then
  load_env
fi

base_domain="${BASE_DOMAIN_INPUT:-${BASE_DOMAIN:-acs.example.com}}"
acme_email="${ACME_EMAIL_INPUT:-${ACME_EMAIL:-admin@example.com}}"
acme_provider="${ACME_PROVIDER_INPUT:-${ACME_DNS_PROVIDER:-cloudflare}}"

mongo_root_password="${MONGO_ROOT_PASSWORD:-$(openssl rand -base64 36 | tr -d '\n')}"
mongo_app_password="${MONGO_APP_PASSWORD:-$(openssl rand -base64 36 | tr -d '\n')}"
ui_jwt_secret="${GENIEACS_UI_JWT_SECRET:-$(openssl rand -hex 64)}"

cat > "${ENV_FILE}" <<EOF_ENV
COMPOSE_PROJECT_NAME=genieacs-auto
BASE_DOMAIN=${base_domain}
ACME_EMAIL=${acme_email}
ACME_DNS_PROVIDER=${acme_provider}
ACME_DNS_PROPAGATION_DELAY=${ACME_DNS_PROPAGATION_DELAY:-30}
TZ=${TZ:-UTC}
TRAEFIK_IMAGE=${TRAEFIK_IMAGE:-traefik:v3.2}
GENIEACS_IMAGE=${GENIEACS_IMAGE:-drumsergio/genieacs:1.2.16.0}
MONGO_IMAGE=${MONGO_IMAGE:-mongo:8.0}
GENIEACS_DB_NAME=${GENIEACS_DB_NAME:-genieacs}
MONGO_ROOT_USERNAME=${MONGO_ROOT_USERNAME:-root}
MONGO_ROOT_PASSWORD=${mongo_root_password}
MONGO_APP_USERNAME=${MONGO_APP_USERNAME:-genieacs}
MONGO_APP_PASSWORD=${mongo_app_password}
GENIEACS_UI_JWT_SECRET=${ui_jwt_secret}
GENIEACS_EXT_DIR=${GENIEACS_EXT_DIR:-./data/ext}
GENIEACS_LOG_DIR=${GENIEACS_LOG_DIR:-./data/logs}
TRAEFIK_DATA_DIR=${TRAEFIK_DATA_DIR:-./data/traefik}
MONGO_DATA_DIR=${MONGO_DATA_DIR:-./data/mongo/db}
MONGO_CONFIGDB_DIR=${MONGO_CONFIGDB_DIR:-./data/mongo/configdb}
UI_HOST=ui.${base_domain}
ACS_HOST=acs.${base_domain}
NBI_HOST=api.${base_domain}
FS_HOST=files.${base_domain}
EOF_ENV

chmod 600 "${ENV_FILE}"
log "Wrote ${ENV_FILE}. Add your DNS-provider-specific ACME credentials to the shell before deploy."
