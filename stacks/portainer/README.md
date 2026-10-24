# Portainer

Container management UI. Accessible at `https://portainer.longie.net` (LAN via Caddy).

> Portainer is **not** a GitOps-managed stack. It is started manually via `docker run` and manages all other stacks. See the root `README.md` for the startup command.

## Architecture

Portainer publishes HTTPS on port `9443`. Caddy proxies `portainer.longie.net` to the host IP — Portainer is not on `proxy_net` since it manages Docker directly via the socket.

```
Browser → Caddy :443 (HTTPS) → 192.168.1.6:9443 → portainer:9443 (self-signed TLS)
```

Caddy skips TLS verification (`tls_insecure_skip_verify`) for the upstream connection since Portainer uses a self-signed cert internally.

## Required environment variables

| Variable | Notes |
|---|---|
| `DOCKER_DATA_HOME` | Host path for Portainer data |

Set at container start time (not via Portainer UI — Portainer is not managing itself).

## Verify after deploy

**1. Container running:**
```bash
docker ps | grep portainer
```

**2. UI accessible:**

Open `https://portainer.longie.net` — should reach the Portainer login screen.
