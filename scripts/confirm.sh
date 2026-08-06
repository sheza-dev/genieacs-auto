#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_command curl
require_command docker
load_env

log "Checking compose health state"
(cd "${REPO_ROOT}" && docker compose ps)

for service in traefik mongo genieacs; do
  container_id="$(cd "${REPO_ROOT}" && docker compose ps -q "${service}")"
  [[ -n "${container_id}" ]] || die "Missing container for service: ${service}"
  health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${container_id}")"
  [[ "${health}" == "healthy" || "${health}" == "running" ]] || die "${service} is not healthy: ${health}"
done

log "Confirming HTTPS endpoints through Traefik"
for host in "${UI_HOST}" "${ACS_HOST}" "${NBI_HOST}" "${FS_HOST}"; do
  code="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' --resolve "${host}:443:127.0.0.1" "https://${host}/")"
  [[ "${code}" =~ ^[1-5][0-9][0-9]$ ]] || die "Unexpected response for ${host}: ${code}"
done

log "Confirmation checks passed."
