# Caddy

Reverse proxy and TLS termination for all HTTPS-exposed services. Uses DNS-01 challenge via Cloudflare to issue real Let's Encrypt certificates — no local CA, no browser warnings.

Also hosts the `cloudflared` container for Cloudflare Tunnel remote access.

## Services proxied

| URL | Backend | Access |
|---|---|---|
| `https://portainer.longie.net` | `192.168.1.6:9443` (TLS) | LAN/Tailscale |
| `https://sonarr.longie.net` | `192.168.1.6:8989` | LAN/Tailscale |
| `https://n8n.longie.net` | `n8n:5678` (remote-access net) | Internet — Cloudflare Tunnel + Access |
| `https://qbt.longie.net` | `192.168.1.6:8080` | LAN/Tailscale |

Jackett (`192.168.1.6:9117`) and Deluge (`192.168.1.6:8112`) are **not** proxied by Caddy — access directly on LAN.

## Networks

- `proxy_net` — connects Caddy to Sonarr; LAN IP routing for portainer/qbt via gluetun host ports
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

## Portainer CSRF "origin invalid" — resolved

`--trusted-origins https://portainer.longie.net` set in `stacks/portainer/docker-compose.yml` since Portainer 2.45.0.

Ref: https://github.com/portainer/portainer/issues/12748

## Known issue: "Pull and redeploy" fails with `Failure [object Object]`

**Symptom:** Portainer CE → caddy stack → Pull and redeploy → instant failure with no useful error message.

**Cause:** This stack uses the `configs:` top-level block with an inline `content:` key — valid Docker Compose spec, but Portainer CE's strict parser (used by the manual redeploy button) chokes on it. The 24h GitOps polling path uses a more lenient parser and works fine.

**Workaround:** Normal config changes deploy automatically via 24h polling — no manual action needed. If you need to force an immediate redeploy (e.g. after port mapping changes), clone the repo on the host and run:

```bash
export DOCKER_DATA_HOME=/your/docker/data/path
export CLOUDFLARE_API_TOKEN=<token>
export CLOUDFLARE_TUNNEL_TOKEN=<token>
docker compose -f stacks/caddy/docker-compose.yml up -d --pull always
```

**Why `configs: content:` is used:** It avoids requiring the Caddyfile to exist as a bind-mounted file on the host, keeping the stack fully self-contained in git. Portainer GitOps bind mounts resolve relative to the `docker compose` runtime path (not the Portainer internal git cache), so a bind mount would require the repo to be cloned on the host anyway.

## Rate limiting

Rate limiting is enforced at the Cloudflare WAF layer — not in Caddy. Blocks brute-force attempts at the edge before traffic reaches the tunnel.

### Cloudflare free tier limitation

The free plan allows **1 rate limiting rule**. To cover multiple login endpoints, use the expression editor to combine them into a single rule:

Navigate to: **Cloudflare Dashboard → your-domain → Security → WAF → Rate limiting rules → Create rule**

| Setting | Value |
|---|---|
| Name | `login-ratelimit` |
| Expression | Use "Edit expression" toggle: `(http.request.uri.path eq "/api/auth") or (http.request.uri.path eq "/rest/login") or (http.request.uri.path eq "/api/v2/auth/login")` |
| Requests | 5 |
| Period | 10 seconds (free tier minimum — no minute-level granularity) |
| Action | Block |
| Duration | 10 seconds |

This single rule covers:
- `/api/auth` — Portainer login
- `/rest/login` — n8n login
- `/api/v2/auth/login` — qBittorrent WebUI login

**What is not covered on free tier:** webhook flood protection and global catch-all rate limiting. This is acceptable because Cloudflare Access OAuth blocks unauthenticated users before they reach any login endpoint.

**Paid tier:** Upgrade to Pro for up to 5 rules with 1-minute windows — allows per-service rules and webhook protection.

### Verify the rule works

```bash
# Should return 429 after 5 rapid attempts
for i in $(seq 1 8); do
  curl -s -o /dev/null -w "%{http_code}\n" \
    -X POST https://your-portainer-domain/api/auth \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"wrong"}'
done
```

Expected: first 5 lines `302` (Portainer redirects unauthenticated requests), subsequent lines `429 Too Many Requests`.

## Adding more services via tunnel

1. Create Cloudflare Access application for the new hostname — **do this first**
2. Connect the service container to `remote-access` network
3. Add Caddyfile block routing to the container by name
4. Add hostname route in Cloudflare Tunnel dashboard → `http://caddy:80`
