# Uptime Kuma

Service uptime monitoring. Accessible at `https://uptime.longie.net` (LAN/Tailscale via Caddy).

## Architecture

Uptime Kuma runs on `proxy_net` so Caddy can proxy it and it can reach other containers by name for HTTP monitors. State is persisted in SQLite at `DOCKER_DATA_HOME/uptime-kuma`.

```
Browser → Caddy :443 → uptime-kuma:3001
```

> **Tag:** Uses `2` (Uptime Kuma v2). Do not use `latest` — it points to EOL v1.

## Required environment variables

Set in Portainer UI → stack → Environment variables:

| Variable | Notes |
|---|---|
| `DOCKER_DATA_HOME` | Host path for Uptime Kuma SQLite database |

## Post-deploy configuration

### 1. First run — create admin account

Navigate to `https://uptime.longie.net` and create the admin account on first visit.

### 2. Add monitors

Dashboard → Add New Monitor (`/add`). Recommended monitors for this setup:

| Name | Type | URL / Host | Notes |
|---|---|---|---|
| Homepage | HTTP(s) | `http://192.168.1.6:3000` | IPv4 |
| Plex | HTTP(s) | `http://192.168.1.6:32400/web` | IPv4 |
| Sonarr | HTTP(s) | `http://192.168.1.6:8989` | IPv4 |
| Tautulli | HTTP(s) | `http://192.168.1.6:8181` | IPv4 |
| Seerr | HTTP(s) | `http://192.168.1.6:5055` | IPv4 |
| qBittorrent | HTTP(s) | `http://192.168.1.6:8080` | IPv4 |
| Deluge | HTTP(s) | `http://192.168.1.6:8112` | IPv4 |
| Prowlarr | HTTP(s) | `http://192.168.1.6:9696` | IPv4 |
| Portainer | HTTP(s) | `https://192.168.1.6:9443` | IPv4 + Ignore TLS errors |
| n8n | HTTP(s) | `https://n8n.longie.net` | |
| Internet | Ping | `8.8.8.8` | |

> **Why LAN IPs?** Uptime Kuma is on `proxy_net`. Services on `proxy_net` (Sonarr, Tautulli, etc.) are reachable by container name, but using LAN IPs works for all services uniformly and also monitors the actual host port binding.

> **Portainer:** Uses a self-signed cert — enable "Ignore TLS/SSL errors for HTTPS websites" in Advanced settings.

### 3. Create status page

Status Pages → New Status Page:

| Field | Value |
|---|---|
| Name | `Home` |
| Slug | `home` |

After creation, click **Add Group**, then use the **Add a monitor** dropdown to add all monitors to the group. Click **Save**.

Status page is accessible at `https://uptime.longie.net/status/home`.

### 4. Homepage widget

The homepage `docker-compose.yml` already includes the uptimekuma widget pointing at the `home` status page:

```yaml
widget:
  type: uptimekuma
  url: http://uptime-kuma:3001
  slug: home
```

No API key required — the widget reads the public status page. Redeploy homepage after any status page slug changes.

## Verify after deploy

**1. Container running:**
```bash
docker ps | grep uptime-kuma
```

**2. UI accessible:**

Open `https://uptime.longie.net` — should reach the dashboard.

**3. All monitors up:**

Dashboard should show all monitors as green (100% Up).

**4. Status page:**

Open `https://uptime.longie.net/status/home` — should show "All Systems Operational".

**5. Homepage widget:**

Open `https://home.longie.net` — Infrastructure section should show the Uptime Kuma tile with live status.
