# Host Scripts

Scripts and configuration files that run natively on the macOS host (not in Docker).

---

## Glances — System Resource Monitor

Provides CPU, memory, and disk metrics to the Homepage dashboard via REST API on port 61208.

### Prerequisites

```bash
brew install glances
```

### Install as login item (auto-start)

```bash
cp net.longie.glances.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/net.longie.glances.plist
```

### Verify

```bash
curl http://localhost:61208/api/4/cpu
```

### Manage

```bash
# Stop
launchctl unload ~/Library/LaunchAgents/net.longie.glances.plist

# Start
launchctl load ~/Library/LaunchAgents/net.longie.glances.plist

# Check logs
tail -f /tmp/glances.log
tail -f /tmp/glances.err
```

### Homepage widget

Configured in `stacks/homepage/docker-compose.yml` under the System group.
Homepage reaches Glances via `http://host.docker.internal:61208`.

---

## Tailscale SSH check — `check-tailscale-ssh.sh`

Reports whether the Tailscale SSH server is running on this node. Context: the
"Tailworm" advisory (2026-10-25) — post-auth privilege escalation in Tailscale SSH.
See `SECURITY.md` → Host dependency advisories.

```bash
bash scripts/check-tailscale-ssh.sh
```

- `RunSSH: false` → OK, not affected (exit 0)
- `RunSSH: true` → warning + mitigation steps (exit 1)

Run on **every** Tailscale device — exposure is per-node, not per-tailnet.

