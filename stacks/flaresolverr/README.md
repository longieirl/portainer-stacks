# FlareSolverr

Cloudflare bypass proxy used by Prowlarr to scrape protected torrent indexers. Routes all traffic through gluetun VPN (`network_mode: container:gluetun`). **gluetun must be running first.**

Not directly accessible from the browser — Prowlarr calls it internally on `localhost:8191`.

## Architecture

FlareSolverr shares gluetun's network namespace. Port 8191 is not exposed on the host — it is only reachable by other containers in the same gluetun namespace (Prowlarr, Jackett).

```
Prowlarr → localhost:8191 (internal, within gluetun network namespace)
Jackett  → localhost:8191 (internal, within gluetun network namespace)
```

## Required environment variables

None — all configuration is hardcoded in `docker-compose.yml`.

## Post-deploy configuration

### Prowlarr integration

Prowlarr → Settings → Indexer Proxies → Add → FlareSolverr:

| Field | Value |
|---|---|
| Host | `http://localhost:8191` |
| Tags | `flaresolverr` |

Then for each Cloudflare-protected indexer in Prowlarr (e.g. EZTV), add the `flaresolverr` tag to the indexer.

### Jackett integration (legacy — remove once Jackett is retired)

Jackett → each indexer that requires Cloudflare bypass → set **FlareSolverr API URL** to `http://localhost:8191`.

## Verify after deploy

**1. FlareSolverr running:**
```bash
docker ps | grep flaresolverr
```

**2. Reachable from Prowlarr:**

Prowlarr → Settings → Indexer Proxies → FlareSolverr → Test — should show green.
