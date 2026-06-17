# gluetun

WireGuard VPN gateway. deluge, jackett, and qbittorrent use `network_mode: container:gluetun` — gluetun must be running before those stacks start.

## Required secret

Set `WIREGUARD_PRIVATE_KEY` in Portainer UI → stack → Environment variables.

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

If the private key is wrong or missing, gluetun will log an auth error and dependent containers (deluge, jackett, qbittorrent) will have no network access.
