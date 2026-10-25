# Prowlarr

Indexer manager that aggregates torrent indexers and syncs them to Sonarr. Routes all traffic through gluetun VPN (`network_mode: container:gluetun`). **gluetun must be running first.**

Accessible at `https://prowlarr.longie.net` (LAN via Caddy).

## Architecture

Prowlarr shares gluetun's network namespace. Port 9696 is declared on the gluetun container (`192.168.1.6:9696:9696`) and is accessible on the host LAN IP.

```
Browser      → Caddy :443 → 192.168.1.6:9696 → Prowlarr
Sonarr sync  → 192.168.1.6:9696 → Prowlarr
FlareSolverr → localhost:8191 (shared gluetun namespace)
```

## Required environment variables

None — all configuration is hardcoded in `docker-compose.yml`.

`DOCKER_DATA_HOME` must be set in Portainer UI at stack creation.

## Post-deploy configuration

### 1. FlareSolverr proxy (Cloudflare bypass)

FlareSolverr also runs in gluetun's network namespace and is reachable at `localhost:8191`.

Prowlarr → Settings → Indexer Proxies → Add → FlareSolverr:

| Field | Value |
|---|---|
| Name | FlareSolverr |
| Host | `http://localhost:8191` |
| Tags | `flaresolverr` |

### 2. Add indexers

Prowlarr → Indexers → Add Indexer. For each indexer blocked by Cloudflare (e.g. EZTV):

- Add the `flaresolverr` tag to the indexer — routes requests through the proxy

Recommended indexers: EZTV, TorrentGalaxy, 1337x.

TV category settings per indexer: `5000` (TV), `5030` (TV/SD), `5040` (TV/HD), `5045` (TV/UHD).

### 3. Sync to Sonarr

Prowlarr → Settings → Apps → Add → Sonarr:

| Field | Value |
|---|---|
| Prowlarr URL | `http://192.168.1.6:9696` |
| Sonarr URL | `http://192.168.1.6:8989` |
| API Key | Sonarr API key (Sonarr → Settings → General) |

Save → Sync Now. All Prowlarr indexers are pushed to Sonarr automatically as Torznab feeds. Any future indexer additions/changes sync automatically.

> **Note:** Sonarr is on `proxy_net` and cannot resolve `prowlarr` by container name — always use the LAN IP `192.168.1.6:9696`.

### 4. Homepage widget

Set `PROWLARR_API_KEY` in Portainer UI for the homepage stack (Prowlarr → Settings → General → API Key), then redeploy homepage.

## Verify after deploy

**1. gluetun running:**
```bash
docker ps | grep gluetun
```

**2. Prowlarr accessible:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://192.168.1.6:9696
```
Expected: `200` or `301`.

**3. FlareSolverr reachable:**

Prowlarr → Settings → Indexer Proxies → FlareSolverr → Test — should show green.

**4. Sonarr sync working:**

Sonarr → Settings → Indexers — should list all Prowlarr indexers as Torznab feeds.
