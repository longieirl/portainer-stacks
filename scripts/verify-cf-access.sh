#!/bin/bash
# Verifies Cloudflare Access is active for all tunnel-exposed hostnames.
# Tests that a direct unauthenticated request gets a CF Access redirect (302/401)
# rather than reaching the backend service (200 with app content).
#
# Run from outside LAN or mobile data — LAN-direct bypasses CF Access by design.

set -euo pipefail

PASS=true

check_access() {
  local name="$1"
  local url="$2"
  local expect_blocked="${3:-true}"  # false for intentionally public paths

  code=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 10 \
    -L \
    "${url}" 2>/dev/null || echo "000")

  if [ "$expect_blocked" = "true" ]; then
    # CF Access redirects to login or returns 403 — never 200 straight through
    if [ "$code" = "200" ]; then
      echo "  FAIL: ${name} — got 200, CF Access may not be active (${url})"
      PASS=false
    elif [ "$code" = "000" ]; then
      echo "  WARN: ${name} — no response / timeout (${url})"
    else
      echo "  PASS: ${name} — got ${code}, Access gate active"
    fi
  else
    # Public bypass path — any response except 000 is acceptable
    if [ "$code" = "000" ]; then
      echo "  WARN: ${name} — no response / timeout (${url})"
    else
      echo "  OK:   ${name} — got ${code} (bypass path, expected public)"
    fi
  fi
}

echo "Cloudflare Access verification"
echo "Note: must run from OUTSIDE LAN (mobile data / VPN) — LAN bypasses CF Access by design"
echo ""

echo "=== Protected hostnames (should NOT return 200 unauthenticated) ==="
check_access "portainer.longie.net" "https://portainer.longie.net"
check_access "sonarr.longie.net"    "https://sonarr.longie.net"
check_access "n8n.longie.net"       "https://n8n.longie.net"
check_access "qbt.longie.net"       "https://qbt.longie.net"
check_access "deluge.longie.net"    "https://deluge.longie.net"
check_access "jackett.longie.net"   "https://jackett.longie.net"

echo ""
echo "=== Bypass paths (public — CF Access intentionally bypassed) ==="
check_access "plex.longie.net (PlexBypass)" "https://plex.longie.net" "false"
check_access "n8n webhook path"             "https://n8n.longie.net/webhook/" "false"

echo ""
if [ "$PASS" = true ]; then
  echo "Result: PASS — CF Access active for all protected hostnames $(date '+%Y-%m-%d')"
  echo ""
  echo "IMPORTANT: A non-200 response confirms the gate is present but does NOT confirm"
  echo "the policy requires YOUR GitHub account. Verify policies in:"
  echo "Cloudflare Zero Trust → Access → Applications → each app → Policies tab"
else
  echo "Result: FAIL — one or more hostnames returned 200 without authentication"
  echo "Check: Cloudflare Zero Trust → Access → Applications → verify policy is Enabled"
  exit 1
fi
