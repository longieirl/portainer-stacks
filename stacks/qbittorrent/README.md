# qbittorrent

Torrent client. Routes all traffic through gluetun VPN (`network_mode: container:gluetun`). **gluetun must be running first.**

WebUI at `https://qbt.longie.net` (LAN/Tailscale via Caddy) or directly at `http://192.168.1.6:8080`.

## Architecture

qBittorrent shares gluetun's network namespace (`network_mode: container:gluetun`). It has no independent network interface. Gluetun publishes port `192.168.1.6:8080` on the host; Caddy proxies `qbt.longie.net` to that port.

```
Browser → Caddy :443 (HTTPS) → 192.168.1.6:8080 → gluetun:8080 → qbittorrent:8080
```

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

**2. WebUI accessible:**

Open `https://qbt.longie.net` or `http://192.168.1.6:8080` — should reach the qBittorrent login screen.

**3. Direct HTTP access works (LAN only):**
```bash
curl -s -o /dev/null -w "%{http_code}" http://192.168.1.6:8080
```
Expected: `200` or redirect — port 8080 is published on the host via gluetun.

**4. Downloads path:**

Settings → Downloads → Default save path should be `/downloads` (maps to `${DOCKER_SHARED_HOME}/qtorrents` on the host).
