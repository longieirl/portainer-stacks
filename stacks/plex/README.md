# plex stack

Tautulli + Overseerr containers for monitoring and media requests against a native (non-Docker) Plex Media Server on the same host.

## Services

| Container | Port | Purpose |
|---|---|---|
| tautulli | 8181 | Analytics, per-user history, notifications |
| overseerr | 5055 | Media requests with Plex auth |

## Prerequisites

- Plex Media Server running natively on host (not in Docker)
- `proxy_net` network exists (created by the caddy stack)
- `DOCKER_DATA_HOME` set in Portainer UI per-stack (Portainer CE has no global env injection)
- Portainer stack name must be `plex` (folder name convention)
- Cloudflare DNS A records exist for `tautulli.longie.net` and `overseerr.longie.net` pointing to the host IP
- Caddy proxy entries added to `stacks/caddy/docker-compose.yml` (see below) and caddy stack redeployed

## Deployment

Portainer → Stacks → **Add Stack** → name: `plex` → **Repository**:

| Field | Value |
|---|---|
| Repository URL | `https://github.com/longieirl/portainer-stacks.git` |
| Branch | `main` |
| Compose path | `stacks/plex/docker-compose.yml` |
| Authentication | Username + PAT |
| GitOps updates mechanism | **Polling**, 24h |

Set in Portainer UI (Environment Variables tab):

| Variable | Value |
|---|---|
| `DOCKER_DATA_HOME` | Your host `$DOCKER_DATA_HOME` value (see repo README setup step 1) |
| `PUID` | Output of `id -u` on host |
| `PGID` | Output of `id -g` on host |

## Connecting to Native Plex

`extra_hosts: host.docker.internal:host-gateway` is set in the compose file. Use `http://host.docker.internal:32400` as the Plex URL in both Tautulli and Overseerr setup wizards.

Plex token: Plex → Settings → General → show advanced → Plex Token.

## Post-Deploy Setup

### Tautulli — `http://192.168.1.6:8181`

1. Settings → Plex Media Server
2. Plex IP: `host.docker.internal`, Port: `32400`
3. Enter Plex token → Save → verify connection

### Overseerr — `http://192.168.1.6:5055`

1. Setup wizard → Plex server URL: `http://host.docker.internal:32400`
2. Enter Plex token
3. Select libraries to sync

## Caddy Proxy Entries

Add to the `caddyfile` content block in `stacks/caddy/docker-compose.yml`:

```
tautulli.longie.net {
    import block_scanners
    import security_headers
    import body_limit
    reverse_proxy tautulli:8181
}

overseerr.longie.net {
    import block_scanners
    import security_headers
    import body_limit
    reverse_proxy overseerr:5055
}
```

After editing the caddy compose: Stacks → caddy → Pull and redeploy.

## Watchtower

Both containers have `com.centurylinklabs.watchtower.enable=true` — covered by the existing watchtower stack nightly run.
