#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"
EXAMPLE_ENV_FILE="${REPO_ROOT}/.env.example"

log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

die() {
  log "ERROR: $*"
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Command not found: $1"
}

ensure_env_file() {
  [[ -f "${ENV_FILE}" ]] || die "Missing ${ENV_FILE}. Run scripts/generate-secrets.sh first."
}

load_env() {
  ensure_env_file
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
}

ensure_dir() {
  mkdir -p "$1"
}

require_non_placeholder() {
  local name="$1"
  local value="$2"
  [[ -n "${value}" ]] || die "${name} must not be empty"
  [[ "${value}" != change-me-* ]] || die "${name} still uses a placeholder value"
  [[ "${value}" != *example.com* ]] || die "${name} still uses an example domain"
  [[ "${value}" != admin@example.com ]] || die "${name} still uses an example email"
}
