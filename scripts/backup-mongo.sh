#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$REPO_DIR/.env}"
BACKUP_DIR="${BACKUP_DIR:-$REPO_DIR/backups/mongo}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE_FILE="$BACKUP_DIR/genieacs-${TIMESTAMP}.archive.gz"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: env file not found at $ENV_FILE"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ -z "${MONGO_ROOT_USERNAME:-}" || -z "${MONGO_ROOT_PASSWORD:-}" ]]; then
  echo "ERROR: MONGO_ROOT_USERNAME/MONGO_ROOT_PASSWORD must be set in $ENV_FILE"
  exit 1
fi

mkdir -p "$BACKUP_DIR"

docker compose --env-file "$ENV_FILE" -f "$REPO_DIR/docker-compose.yml" exec -T mongo \
  mongodump \
  --username "$MONGO_ROOT_USERNAME" \
  --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --archive \
  --gzip > "$ARCHIVE_FILE"

find "$BACKUP_DIR" -type f -name '*.archive.gz' -mtime "+$RETENTION_DAYS" -delete

echo "Backup created: $ARCHIVE_FILE"
echo "Retention: deleted backups older than $RETENTION_DAYS day(s)"
