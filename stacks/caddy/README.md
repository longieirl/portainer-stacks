# Caddy

Reverse proxy and TLS termination for all HTTPS-exposed services. Uses DNS-01 challenge via Cloudflare to issue real Let's Encrypt certificates — no local CA, no browser warnings.

Also hosts the `cloudflared` container for Cloudflare Tunnel remote access.

## Services proxied

| URL | Backend | Access |
|---|---|---|
| `https://portainer.longie.net` | `192.168.1.6:9443` (TLS) | LAN + Tunnel (GitHub OAuth) |
| `https://sonarr.longie.net` | `192.168.1.6:8989` | LAN + Tunnel (GitHub OAuth) |
| `https://n8n.longie.net` | `n8n:5678` (remote-access net) | Tunnel only (GitHub OAuth) |
| `https://jackett.longie.net` | `192.168.1.6:9117` | LAN only |
| `https://qbt.longie.net` | `192.168.1.6:8080` | LAN only |
| `https://deluge.longie.net` | `192.168.1.6:8112` | LAN only |

## Networks

- `proxy_net` — connects Caddy and cloudflared; LAN IP routing for portainer/sonarr
- `remote-access` — connects Caddy to n8n container by name; external network, pre-created

## Required environment variables

Set in Portainer UI → stack → Environment variables (never commit real values):

| Variable | Notes |
|---|---|
| `DOCKER_DATA_HOME` | Host path for persistent Caddy data — must be under a Docker Desktop shared path (Preferences → Resources → File Sharing). Example: `/Users/yourname/docker-data` |
| `CLOUDFLARE_API_TOKEN` | DNS Edit token for `longie.net` zone — used for DNS-01 cert issuance |
| `CLOUDFLARE_TUNNEL_TOKEN` | Cloudflare Tunnel token for `longie-caddy` tunnel |

## Deploy order

1. Pre-create `remote-access` network if not already present:
   ```bash
   docker network create remote-access
   ```
2. Set all three env vars in Portainer UI for this stack
3. Deploy caddy stack — Caddy will issue certs on first start (~60s)
4. Deploy n8n stack (joins `remote-access`)

## Verify after deploy

```bash
# Caddy and cloudflared running
docker ps | grep -E "caddy|cloudflared"

# Caddy can reach n8n
docker exec caddy wget -q -O- http://n8n:5678 | head -3

# cloudflared tunnel healthy
docker logs cloudflared-caddy --tail 5
```

## Known issue: Portainer CSRF "origin invalid" via reverse proxy

**Symptom:** Write operations (redeploy, pull, env changes) via `https://portainer.longie.net` fail with "Forbidden - origin invalid".

**Cause:** Portainer CE 2.39.4 CSRF validation compares the `Origin` header against `x_forwarded_proto://host`. Via Cloudflare Tunnel, Caddy receives plain HTTP so the scheme is `http`, and the upstream host leaks as `192.168.1.6:9443` — neither matches `portainer.longie.net`. The `--trusted-origins` flag is broken in CE 2.39.4 (crashes Portainer on startup).

**Fix (already applied):** Both portainer Caddyfile blocks explicitly set:
```
header_up Host portainer.longie.net
header_up Origin https://portainer.longie.net
```

**Upstream bug:** https://github.com/portainer/portainer/issues/12748
**Local tracking:** https://github.com/longieirl/portainer-stacks/issues/38

## Adding more services via tunnel

1. Create Cloudflare Access application for the new hostname — **do this first**
2. Connect the service container to `remote-access` network
3. Add Caddyfile block routing to the container by name
4. Add hostname route in Cloudflare Tunnel dashboard → `http://caddy:80`

See `docs/superpowers/specs/2026-07-09-cloudflare-tunnel-access-design.md` for full architecture.
