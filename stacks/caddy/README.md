# Caddy

Reverse proxy and TLS termination for all HTTPS-exposed services. Uses Caddy's `tls internal` to auto-generate a local CA — no manual certificate management required.

## Services proxied

| URL | Backend |
|---|---|
| `https://192.168.1.6` | n8n :5678 |
| `https://192.168.1.6:8080` | qBittorrent :8080 (via gluetun) |
| `https://192.168.1.6:8989` | Sonarr :8989 |

`http://192.168.1.6` (port 80) redirects to HTTPS automatically. Ports 8080 and 8989 are HTTPS-only — there is no HTTP redirect on those ports; accessing them via `http://` shows a protocol error rather than a redirect. Use `https://` directly.

## Why a dedicated Caddy stack?

Running one Caddy instance shared across stacks is simpler than embedding a proxy in each stack. The `proxy_net` Docker network is owned here — n8n and Sonarr join it as `external: true`. This means:

- One place to update routing rules
- One CA cert to trust on your machine
- No duplicate port 80/443 bindings across stacks

## Deploy order

**Caddy must be deployed first.** n8n and Sonarr declare `proxy_net` as an external network. If it doesn't exist, those stacks will fail to start.

## First-time setup: trust Caddy's local CA

Caddy generates its own certificate authority on first start. Browsers will warn until you trust it.

After the caddy stack starts for the first time, run on the Docker host:

```bash
docker cp caddy:/data/caddy/pki/authorities/local/root.crt ~/caddy-root.crt
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain ~/caddy-root.crt
```

Restart your browser. All `https://192.168.1.6` URLs will load without warnings.

> This is a one-time step per Mac. The CA persists in Caddy's `/data` volume — it survives container restarts and redeployments.

**Safari note:** You may also need to accept the cert in System Settings → Privacy & Security → Certificates after running the command above.

## Required environment variable

Set in Portainer UI → stack → Environment variables:

| Variable | Notes |
|---|---|
| `DOCKER_DATA_HOME` | Host path for persistent Caddy data (TLS CA, config cache) |

## Verify after deploy

**1. Container running:**
```bash
docker ps | grep caddy
```
Expected: `caddy` shows `Up`.

**2. HTTP redirects to HTTPS:**
```bash
curl -I http://192.168.1.6
```
Expected: `301` redirect to `https://192.168.1.6`.

**3. n8n reachable over HTTPS:**

Open `https://192.168.1.6` — should load the n8n login screen.

**4. Sonarr reachable over HTTPS:**

Open `https://192.168.1.6:8989` — should load the Sonarr UI.

## Adding more services

Edit the Caddyfile in `docker-compose.yml` `configs.caddyfile.content` and add a new block:

```
:PORT {
    tls internal
    reverse_proxy container-name:PORT
}
```

Then add the new service's stack to `proxy_net` as `external: true`, and redeploy both stacks.
