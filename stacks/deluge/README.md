# Deluge

Torrent client. Routes all traffic through gluetun VPN (`network_mode: container:gluetun`). **gluetun must be running first.**

WebUI at `http://192.168.1.6:8112` (LAN direct only — not proxied via Caddy).

## Architecture

Deluge shares gluetun's network namespace. It has no independent network interface. Gluetun publishes port `192.168.1.6:8112` on the host.

```
Browser → 192.168.1.6:8112 → gluetun:8112 → deluge:8112
```

> All torrent traffic exits via WireGuard VPN. If gluetun goes down, Deluge loses network entirely (kill-switch behaviour by design).

## Required environment variables

Set in Portainer UI → stack → Environment variables:

| Variable | Notes |
|---|---|
| `DOCKER_DATA_HOME` | Host path for Deluge config |
| `DOCKER_SHARED_HOME` | Host path for shared downloads folder |

## Post-deploy configuration

First login uses default credentials (`admin` / `deluge`). Change immediately:

Preferences → Interface → Password

## Verify after deploy

**1. gluetun running:**
```bash
docker ps | grep gluetun
```
Deluge has no network without it.

**2. WebUI accessible:**

Open `http://192.168.1.6:8112` — should reach the Deluge login screen.

**3. VPN active (from Deluge):**

Preferences → Network — the IP shown should be the VPN exit IP, not your home IP.
