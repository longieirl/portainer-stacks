# Jackett

Torrent indexer proxy. Translates tracker searches from Sonarr/Deluge/qBittorrent into a unified API. Routes all traffic through gluetun VPN (`network_mode: container:gluetun`). **gluetun must be running first.**

WebUI at `http://192.168.1.6:9117` (LAN direct only — not proxied via Caddy).

## Architecture

Jackett shares gluetun's network namespace. Gluetun publishes port `192.168.1.6:9117` on the host.

```
Browser → 192.168.1.6:9117 → gluetun:9117 → jackett:9117
Sonarr → 192.168.1.6:9117 → gluetun:9117 → jackett:9117
```

> All indexer traffic exits via WireGuard VPN.

## Required environment variables

Set in Portainer UI → stack → Environment variables:

| Variable | Notes |
|---|---|
| `DOCKER_DATA_HOME` | Host path for Jackett config |
| `DOCKER_SHARED_HOME` | Host path for shared downloads folder |

## Post-deploy configuration

**1. Set an admin password:**

Jackett WebUI → scroll to bottom → Admin password → set and save.

**2. Add indexers:**

Jackett → Add Indexer → search and add your preferred trackers.

**3. Configure Sonarr to use Jackett:**

Sonarr → Settings → Indexers → Add → Torznab → use the Jackett API URL and key shown in the Jackett WebUI.

**4. FlareSolverr (optional):**

For Cloudflare-protected indexers, set FlareSolverr API URL to `http://localhost:8191` in Jackett settings (requires flaresolverr stack running).

## Verify after deploy

**1. gluetun running:**
```bash
docker ps | grep gluetun
```

**2. WebUI accessible:**

Open `http://192.168.1.6:9117` — should reach the Jackett dashboard.
