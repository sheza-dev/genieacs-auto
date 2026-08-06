#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_command docker
load_env

backup_dir="${1:-${REPO_ROOT}/backups}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
archive_dir="${backup_dir}/${timestamp}"
ensure_dir "${archive_dir}"

log "Creating MongoDB archive in ${archive_dir}"
(cd "${REPO_ROOT}" && docker compose exec -T mongo mongodump \
  --username "${MONGO_ROOT_USERNAME}" \
  --password "${MONGO_ROOT_PASSWORD}" \
  --authenticationDatabase admin \
  --archive) > "${archive_dir}/mongo.archive"

tar -C "${REPO_ROOT}" -czf "${archive_dir}/genieacs-ext-and-logs.tar.gz" data/ext data/logs
log "Backup completed: ${archive_dir}"
