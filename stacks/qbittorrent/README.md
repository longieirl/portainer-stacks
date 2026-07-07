# qbittorrent

Torrent client. Routes all traffic through gluetun VPN (`network_mode: container:gluetun`). **gluetun must be running first.**

WebUI at `https://192.168.1.6:8080` — HTTPS terminated by Caddy. Port 8080 is no longer published directly on the host.

## Architecture

qBittorrent shares gluetun's network namespace (`network_mode: container:gluetun`). It has no independent network interface. Caddy reaches it via the gluetun container on `proxy_net`:

```
Browser → Caddy :8080 (HTTPS) → gluetun:8080 → qbittorrent:8080
```

gluetun joins `proxy_net` so Caddy can reach it. Port 8080 is removed from gluetun's host port mappings — WebUI is only accessible via Caddy.

## First-time login

linuxserver/qbittorrent generates a random password on first start. Get it from the logs:

```bash
docker logs qbittorrent 2>&1 | grep -i password
```

Look for:
```
A temporary password is provided for this session: XXXXXXXX
```

Log in with username `admin` and that temporary password.

**Immediately after login:** Settings → Web UI → Password → set a permanent password → Save.

## Verify after deploy

**1. gluetun running:**
```bash
docker ps | grep gluetun
```
qbittorrent has no network without it.

**2. WebUI accessible over HTTPS:**

Open `https://192.168.1.6:8080` — should reach the qbittorrent login screen. See the Caddy stack README for CA trust setup if the browser shows a certificate warning.

**3. No direct HTTP access (expected to fail):**
```bash
curl http://192.168.1.6:8080
```
Expected: connection refused. Port 8080 is no longer published on the host.

**4. Downloads path:**

Settings → Downloads → Default save path should be `/downloads` (maps to `${DOCKER_SHARED_HOME}/qtorrents` on the host).
