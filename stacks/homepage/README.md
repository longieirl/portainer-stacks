# Homepage

Self-hosted dashboard with live service widgets. Accessible at `https://home.longie.net` (LAN via Caddy) and externally via Cloudflare Tunnel with Access policy.

## Architecture

Homepage runs on `proxy_net` so it can reach other containers by name for widget API calls. Caddy terminates TLS for LAN access; Cloudflare Tunnel handles external access.

```
LAN:      Browser → Caddy :443 → homepage:3000
External: Browser → Cloudflare Tunnel → Caddy → homepage:3000
```

Configuration (services, settings, widgets, bookmarks) is embedded directly in `docker-compose.yml` as Docker `configs:` blocks — no separate files to manage. A volume at `DOCKER_DATA_HOME/homepage/config` stores writable state (database, logs).

## Widget URL pattern

Homepage is on `proxy_net`. Widget URLs depend on the target service's network:

| Service network | URL pattern | Examples |
|---|---|---|
| `proxy_net` | `http://<container-name>:<port>` | Sonarr, Tautulli, Seerr, Uptime Kuma |
| `container:gluetun` | `http://192.168.1.6:<port>` | qBittorrent (8080), Deluge (8112), Prowlarr (9696) |
| Host process | `http://host.docker.internal:<port>` | Plex (32400), Glances (61208) |

Services in the gluetun namespace are **not** on `proxy_net` and have no container DNS entry. Their host port binding on `192.168.1.6` is the only way Homepage can reach them.

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
| `PROWLARR_API_KEY` | Prowlarr → Settings → General → API Key |

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

| Widget | Expected |
|---|---|
| Plex | Stream count, movie/TV library totals |
| Tautulli | Recent play activity |
| Sonarr | Wanted/queued/series counts |
| Seerr | Pending/processing/available request counts |
| qBittorrent | Active torrent count |
| Deluge | Active torrent count |
| Prowlarr | Enabled indexers, grab counts |
| Uptime Kuma | Status summary from `home` status page |
| Glances (CPU/Memory/Disk/Network) | Live system metrics |

If a widget shows an error, check:
- API key is set in Portainer UI for that variable
- For gluetun-namespaced services: gluetun is running and the port is mapped (see `stacks/gluetun/README.md`)
- For `host.docker.internal` services: the process is running on the host
