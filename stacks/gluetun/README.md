# gluetun

WireGuard VPN gateway. deluge, jackett, qbittorrent, prowlarr, and flaresolverr use `network_mode: container:gluetun` — gluetun must be running before those stacks start.

## Architecture

Containers using `network_mode: container:gluetun` share gluetun's network namespace. They have no independent network stack:

- No container DNS entry on `proxy_net` (unreachable by name from Homepage, Caddy, etc.)
- Communicate with each other via `localhost` (same namespace)
- All internet traffic routed through WireGuard VPN
- Accessible from the host LAN **only** via port mappings declared on the gluetun container

```
Host LAN → 192.168.1.6:<port> → gluetun → container
```

### Current port mappings

| Port | Service | Used by |
|---|---|---|
| 8080 | qBittorrent WebUI | Homepage widget, LAN direct |
| 8112 | Deluge WebUI | Homepage widget, LAN direct |
| 9117 | Jackett WebUI | LAN direct (legacy) |
| 9696 | Prowlarr WebUI | Homepage widget, Caddy (prowlarr.longie.net), Sonarr sync |

### Adding a new service to the gluetun namespace

1. Add `network_mode: container:gluetun` to the service in its own stack — **do not** declare `ports:` there.
2. Add `- 192.168.1.6:<host-port>:<container-port>` to gluetun's `ports:` in `stacks/gluetun/docker-compose.yml`.
3. Add the port to `FIREWALL_INPUT_PORTS` in gluetun's env vars (opens the VPN firewall, separate from host port binding).
4. Redeploy gluetun, then restart dependent containers: `docker restart <name>`.

> `FIREWALL_INPUT_PORTS` alone is not enough — it only opens the VPN-side firewall. The host port binding in `ports:` is required for LAN/Caddy access.

## Required secret

Set `WIREGUARD_PRIVATE_KEY` in Portainer UI → stack → Environment variables.

## After gluetun redeploy

Dependent containers lose network access when gluetun restarts. Restart them after redeploy:

```bash
docker restart qbittorrent deluge jackett prowlarr flaresolverr
```

## Verify after deploy

**1. Check VPN connected:**
```bash
docker logs gluetun 2>&1 | grep -E "VPN|connected|wireguard setup|error" | tail -20
```
Expected: `wireguard setup is complete`

**2. Confirm traffic routes through VPN (not home IP):**
```bash
docker exec gluetun wget -qO- https://ipinfo.io/ip
```
Expected: a Surfshark IP in New York, not your home IP.

If the private key is wrong or missing, gluetun will log an auth error and dependent containers will have no network access.

## Kill switch verification

Run after any gluetun config changes or monthly:

```bash
bash scripts/test-gluetun-killswitch.sh
```

Stops gluetun, confirms qbittorrent has no internet access, then restarts and confirms VPN restored. Last verified: 2026-08-03 (PASS).
