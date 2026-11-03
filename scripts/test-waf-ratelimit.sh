#!/bin/bash
# Tests Cloudflare WAF rate-limit rule covers all three login endpoints.
# Expected: first 5 requests return the app's normal response (401/302/200),
# subsequent requests return 429 Too Many Requests from Cloudflare.
#
# Requires: curl, the three services reachable via tunnel (not LAN-direct).

set -euo pipefail

PORTAINER_URL="${PORTAINER_URL:-https://portainer.longie.net}"
N8N_URL="${N8N_URL:-https://n8n.longie.net}"
QBT_URL="${QBT_URL:-https://qbt.longie.net}"

PASS=true

test_endpoint() {
  local name="$1"
  local url="$2"
  local method="$3"
  local data="$4"
  local content_type="${5:-application/json}"

  echo ""
  echo "=== ${name} ==="
  echo "Sending 8 rapid POST requests to ${url}..."

  local got_429=false
  for i in $(seq 1 8); do
    code=$(curl -s -o /dev/null -w "%{http_code}" \
      --max-time 10 \
      -X "${method}" "${url}" \
      -H "Content-Type: ${content_type}" \
      -d "${data}" 2>/dev/null || echo "000")
    echo "  Request ${i}: HTTP ${code}"
    if [ "$code" = "429" ]; then
      got_429=true
    fi
  done

  if [ "$got_429" = true ]; then
    echo "  PASS: Got 429 — rate-limit rule active for ${name}"
  else
    echo "  FAIL: No 429 received — rate-limit rule may not be active for ${name}"
    PASS=false
  fi
}

echo "Cloudflare WAF rate-limit verification"
echo "Rule: login-ratelimit (5 req / 10s → block)"
echo "Note: must run from outside LAN or via VPN — Cloudflare only intercepts tunnel traffic"
echo ""
echo "Waiting 15s for any previous rate-limit window to expire..."
sleep 15

test_endpoint "Portainer /api/auth" \
  "${PORTAINER_URL}/api/auth" \
  "POST" \
  '{"username":"admin","password":"wrongpassword"}'

sleep 15

test_endpoint "n8n /rest/login" \
  "${N8N_URL}/rest/login" \
  "POST" \
  '{"email":"admin@example.com","password":"wrongpassword"}'

sleep 15

test_endpoint "qBittorrent /api/v2/auth/login" \
  "${QBT_URL}/api/v2/auth/login" \
  "POST" \
  "username=admin&password=wrongpassword" \
  "application/x-www-form-urlencoded"

echo ""
if [ "$PASS" = true ]; then
  echo "Result: PASS — WAF rate-limit rule verified $(date '+%Y-%m-%d')"
else
  echo "Result: FAIL — check Cloudflare Dashboard → longie.net → Security → WAF → Rate limiting rules"
  echo "  Confirm 'login-ratelimit' rule is Enabled with correct expression and threshold"
  exit 1
fi
