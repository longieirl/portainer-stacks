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

## Upgrading Portainer

Portainer pins an explicit version tag — Watchtower is disabled for this container. Steps to upgrade:

**1. Update the version in compose**

Edit `stacks/portainer/docker-compose.yml`, bump `image: portainer/portainer-ce:<version>`, open a PR, merge to main.

**2. Pull the repo on the host**

```bash
cd /path/to/portainer-stacks
git pull
```

**3. Recreate the container**

Run from the repo root:

```bash
DOCKER_DATA_HOME="${HOME}/Documents/docker/data" \
  docker compose -f stacks/portainer/docker-compose.yml pull

DOCKER_DATA_HOME="${HOME}/Documents/docker/data" \
  docker compose -f stacks/portainer/docker-compose.yml up -d
```

**4. Verify**

```bash
docker ps | grep portainer   # should show new version tag
docker logs portainer --tail 5
```

Open `https://portainer.longie.net` — Portainer logs a migration line if the DB was upgraded.

> **macOS Docker Desktop note:** `ports: - 9443:9443` without an explicit host IP binds to `127.0.0.1` only, blocking LAN access. The compose uses `192.168.1.6:9443:9443` to avoid this — do not change it to the short form.
