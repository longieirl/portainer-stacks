# Sonarr

TV series management. Accessible at `https://sonarr.longie.net` (LAN/Tailscale via Caddy).

## Architecture

Sonarr publishes port `192.168.1.6:8989` on the host and joins `proxy_net` so Caddy can reach it by host IP. Caddy terminates TLS and proxies to Sonarr — no TLS cert needed on Sonarr itself.

```
Browser → Caddy :443 (HTTPS) → 192.168.1.6:8989 → sonarr:8989
```

**Why route through Caddy instead of direct HTTP?**

Sonarr has no built-in TLS support. Routing through Caddy means all traffic is encrypted without any changes to Sonarr itself.

> **Deploy Caddy first.** The `proxy_net` network is owned by the caddy stack. Sonarr will fail to start if it doesn't exist yet.

## Required environment variables

Set in Portainer UI → stack → Environment variables:

| Variable | Notes |
|---|---|
| `DOCKER_DATA_HOME` | Host path for Sonarr config |
| `DOCKER_SHARED_HOME` | Host path for shared downloads folder |

## Verify after deploy

**1. Container running:**
```bash
docker ps | grep sonarr
```
Expected: `sonarr` shows `Up`.

**2. Sonarr UI loads over HTTPS:**

Open `https://sonarr.longie.net` — should reach the Sonarr UI.

**3. Verify direct HTTP also works (LAN only):**
```bash
curl -s -o /dev/null -w "%{http_code}" http://192.168.1.6:8989
```
Expected: `200` or `301` — port is published on host for LAN direct access and Sonarr→Jackett indexer calls.
