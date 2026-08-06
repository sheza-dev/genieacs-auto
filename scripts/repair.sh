#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_command docker
require_command python3
load_env
"${SCRIPT_DIR}/secure.sh"

log "Re-applying compose configuration"
(cd "${REPO_ROOT}" && docker compose up -d --force-recreate --remove-orphans)

unhealthy_services="$(cd "${REPO_ROOT}" && docker compose ps --format json | python3 -c 'import json, sys
services = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    item = json.loads(line)
    health = (item.get("Health") or "").lower()
    state = (item.get("State") or "").lower()
    if "unhealthy" in health or state not in ("running", ""):
        services.append(item["Service"])
print(" ".join(dict.fromkeys(services)))')"

if [[ -n "${unhealthy_services}" ]]; then
  log "Restarting unhealthy services: ${unhealthy_services}"
  (cd "${REPO_ROOT}" && docker compose restart ${unhealthy_services})
fi

"${SCRIPT_DIR}/confirm.sh"
