# FlareSolverr

Cloudflare bypass proxy used by Jackett to scrape protected torrent indexers. Routes all traffic through gluetun VPN (`network_mode: container:gluetun`). **gluetun must be running first.**

Not directly accessible from the browser — Jackett calls it internally on port `8191`.

## Architecture

FlareSolverr shares gluetun's network namespace. Port 8191 is not exposed on the host — it is only reachable by Jackett (which also shares gluetun's network namespace).

```
Jackett → flaresolverr:8191 (internal, within gluetun network)
```

## Required environment variables

None — all configuration is hardcoded in `docker-compose.yml`.

## Post-deploy configuration

In Jackett → each indexer that requires Cloudflare bypass:

- Set **FlareSolverr API URL** to `http://localhost:8191`

## Verify after deploy

**1. gluetun running:**
```bash
docker ps | grep gluetun
```

**2. FlareSolverr running:**
```bash
docker ps | grep flaresolverr
```

**3. Reachable from Jackett:**

Test via Jackett — add an indexer that uses FlareSolverr and run a test search.
