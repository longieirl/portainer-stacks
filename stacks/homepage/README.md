# Homepage

Self-hosted dashboard with live service widgets. Accessible at `https://home.longie.net` (LAN via Caddy) and externally via Cloudflare Tunnel with Access policy.

## Architecture

Homepage runs on `proxy_net` so it can reach other containers by name for widget API calls. Caddy terminates TLS for LAN access; Cloudflare Tunnel handles external access.

```
LAN:      Browser → Caddy :443 → homepage:3000
External: Browser → Cloudflare Tunnel → Caddy → homepage:3000
```

Configuration (services, settings, widgets, bookmarks) is embedded directly in `docker-compose.yml` as Docker `configs:` blocks — no separate files to manage. A volume at `DOCKER_DATA_HOME/homepage/config` stores writable state (database, logs).

## Required environment variables

Set in Portainer UI → stack → Environment variables:

| Variable | Notes |
|---|---|
| `DOCKER_DATA_HOME` | Host path for Homepage state (db, logs) |
| `PUID` | Host user ID (`id -u`) |
| `PGID` | Host group ID (`id -g`) |
| `PLEX_TOKEN` | Plex Settings → General → Plex Token |
| `TAUTULLI_API_KEY` | Tautulli → Settings → Web Interface → API Key |
| `SONARR_API_KEY` | Sonarr → Settings → General → API Key |
| `SEERR_API_KEY` | Seerr → Settings → General → API Key |
| `QBIT_USERNAME` | qBittorrent WebUI username (default: `admin`) |
| `QBIT_PASSWORD` | qBittorrent WebUI password |
| `DELUGE_PASSWORD` | Deluge WebUI password |

## Updating the dashboard

All config is in `docker-compose.yml`. Edit the `configs:` section, commit, then in Portainer: Pull and redeploy.

## Verify after deploy

**1. Container running:**
```bash
docker ps | grep homepage
```

**2. Dashboard loads:**

Open `https://home.longie.net` — should show all service tiles.

**3. Widgets showing data:**

Plex, Tautulli, Sonarr, and Seerr tiles should show live counts. If a widget shows an error, check the API key for that service.
