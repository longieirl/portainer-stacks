#!/bin/bash
set -euo pipefail

# Checks whether the Tailscale SSH server is running on this node.
# Context: "Tailworm" advisory (2026-10-25) — post-auth privilege escalation
# in the Tailscale SSH feature. See SECURITY.md → Host dependency advisories.
# Run on EVERY Tailscale device — exposure is per-node.

if ! command -v tailscale >/dev/null 2>&1; then
  echo "SKIP: tailscale CLI not found on this host."
  exit 0
fi

RUN_SSH=$(tailscale debug prefs 2>/dev/null | grep -i '"RunSSH"' | grep -oE 'true|false' || echo "unknown")

echo "=== Tailscale SSH status ($(hostname)) ==="
echo "RunSSH: ${RUN_SSH}"

case "${RUN_SSH}" in
  false)
    echo "OK: Tailscale SSH server is OFF. Not affected by Tailworm."
    exit 0
    ;;
  true)
    echo "WARNING: Tailscale SSH server is ON — this node is in scope for Tailworm."
    echo "Mitigate: set TS_SSH_DISABLE_FORWARDING=1 in the tailscaled environment,"
    echo "scope the ssh ACL to named source→destination pairs, and track the advisory:"
    echo "  https://tailscale.com/security-bulletins"
    exit 1
    ;;
  *)
    echo "UNKNOWN: could not read RunSSH from 'tailscale debug prefs'. Check manually."
    exit 2
    ;;
esac
