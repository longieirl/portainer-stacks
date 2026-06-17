# qbittorrent

Torrent client. Routes all traffic through gluetun VPN (`network_mode: container:gluetun`). **gluetun must be running first.**

WebUI at `http://192.168.1.6:8080`.

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

Open `http://192.168.1.6:8080` — should reach the qbittorrent login screen.

**3. Downloads path:**

Settings → Downloads → Default save path should be `/downloads` (maps to `${DOCKER_SHARED_HOME}/qtorrents` on the host — outside the backup path).
