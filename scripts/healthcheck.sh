#!/usr/bin/env bash
set -euo pipefail

ACS_HOST="${ACS_HOST:-acs.shezanet.net}"
UI_HOST="${UI_HOST:-ui.shezanet.net}"
NBI_HOST="${NBI_HOST:-nbi.shezanet.net}"
FS_HOST="${FS_HOST:-fs.shezanet.net}"
INSECURE_TLS="${INSECURE_TLS:-false}"

curl_opts=(--silent --show-error --output /dev/null --write-out "%{http_code}" --max-time 10)
if [[ "$INSECURE_TLS" == "true" ]]; then
  curl_opts+=(--insecure)
fi

check_http() {
  local name="$1"
  local url="$2"
  local code

  code="$(curl "${curl_opts[@]}" "$url" || true)"
  if [[ "$code" =~ ^[1-4][0-9][0-9]$ ]]; then
    echo "[OK]  $name -> $url (HTTP $code)"
  else
    echo "[FAIL] $name -> $url (HTTP ${code:-000})"
    return 1
  fi
}

status=0
check_http "nginx-health" "https://${ACS_HOST}/healthz" || status=1
check_http "cwmp" "https://${ACS_HOST}/" || status=1
check_http "ui" "https://${UI_HOST}/" || status=1
check_http "nbi" "https://${NBI_HOST}/" || status=1
check_http "fs" "https://${FS_HOST}/" || status=1

exit "$status"
