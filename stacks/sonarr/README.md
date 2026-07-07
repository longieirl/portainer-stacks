# Sonarr

TV series management. Accessible at `https://192.168.1.6:8989`.

## Architecture

Sonarr has no host port. It is only reachable via Caddy on `proxy_net`. Direct access on port 8989 is blocked at the Docker level.

```
Browser → Caddy :8989 (HTTPS, tls internal) → sonarr:8989 (proxy_net)
```

**Why no direct port exposure?**

Sonarr has no built-in TLS support. Publishing port 8989 directly to the host would send the API key and session over plain HTTP. Routing through Caddy means all traffic is encrypted without any changes to Sonarr itself.

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

Open `https://192.168.1.6:8989` — should reach the Sonarr UI. See the Caddy stack README for CA trust setup if the browser shows a certificate warning.

**3. No direct HTTP access (expected to fail):**
```bash
curl http://192.168.1.6:8989
```
Expected: connection refused. Port 8989 is not published on the host.
