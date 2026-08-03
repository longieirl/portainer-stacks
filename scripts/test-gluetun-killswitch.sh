#!/bin/bash
set -euo pipefail

echo "=== Baseline: VPN IP ==="
VPN_IP=$(docker exec gluetun wget -qO- https://ifconfig.me 2>/dev/null) || {
  echo "ERROR: gluetun not running or no internet. Aborting."
  exit 1
}
echo "VPN IP: ${VPN_IP}"
echo ""

echo "=== Stopping gluetun to simulate VPN drop ==="
docker stop gluetun
sleep 5

echo "=== Test: qbittorrent internet access without VPN ==="
RESULT=$(docker exec qbittorrent curl --max-time 10 -s https://ifconfig.me 2>&1 || true)

if [ -z "$RESULT" ] || echo "$RESULT" | grep -qiE "timed out|Connection refused|Network unreachable|Failed to connect|Could not resolve"; then
  echo "PASS: Kill switch working — qbittorrent cannot reach internet without VPN"
  PASSED=true
else
  echo "FAIL: Kill switch NOT working — got: ${RESULT}"
  PASSED=false
fi

echo ""
echo "=== Restarting gluetun ==="
docker start gluetun
echo "Waiting 15s for VPN to reconnect..."
sleep 15

echo "=== Verify VPN restored ==="
RESTORED_IP=$(docker exec gluetun wget -qO- https://ifconfig.me 2>/dev/null) || RESTORED_IP="unknown"
echo "VPN IP after restart: ${RESTORED_IP}"

echo ""
if [ "$PASSED" = true ]; then
  echo "Result: PASS — kill switch verified $(date '+%Y-%m-%d')"
else
  echo "Result: FAIL — kill switch NOT working, investigate gluetun firewall config"
  exit 1
fi
