# homeassistant

Home Assistant for managing Zigbee devices and smart TRVs (thermostatic radiator
valves), as a local replacement for the SmartLife (Tuya) app. Accessible at
`https://homeassistant.longie.net` (LAN) and `http://192.168.1.6:8123` (direct).

This stack ships a **two-phase feature flag** so you can start without buying
hardware, then switch to fully-local Zigbee when a coordinator arrives.

## Which phase do I use?

| | **Phase 1 (default)** | **Phase 2** |
|---|---|---|
| Flag | `COMPOSE_PROFILES` unset | `COMPOSE_PROFILES=zigbee` |
| Runs | `homeassistant` | + `mosquitto` + `zigbee2mqtt` |
| Zigbee control | via the **Tuya cloud** integration (your existing gateway) | **local** via a Zigbee coordinator |
| Extra hardware | none | a **network** Zigbee coordinator (e.g. SMLIGHT SLZB-06) |
| Cloud dependency | yes (Tuya servers) | none |
| Re-pair devices | no | yes (one-time) |
| Best for | trying HA, no hardware yet, Wi-Fi/Tuya devices | lowest latency, offline control, privacy |

**Short version:** Phase 1 is a stepping stone — it's SmartLife's cloud with an HA
dashboard on top. Phase 2 is the actual upgrade. Start at Phase 1, flip to Phase 2
once your coordinator is delivered. No file change needed to switch — just set the
env var and redeploy.

## Why a *network* coordinator, not a USB dongle

This Portainer host runs **Docker Desktop on macOS**. Linux containers run inside a
LinuxKit VM with **no USB passthrough** — a USB Zigbee dongle plugged into the Mac
is invisible to a container. `devices:` and `network_mode: host` resolve inside the
VM, not on the Mac.

So Phase 2 requires a coordinator that speaks over the **network (TCP)**, e.g. the
Ethernet/PoE **SMLIGHT SLZB-06** (TI CC2652P). `zigbee2mqtt` connects to it at
`tcp://<ip>:6638`.

## The feature flag

`COMPOSE_PROFILES` is set in Portainer UI → stack → Environment variables.

- unset / empty → Phase 1
- `zigbee` → Phase 2

> **Use the single value `zigbee`.** Comma-separated profile lists
> (`a,b`) are truncated by a Portainer bug
> ([portainer/portainer#13033](https://github.com/portainer/portainer/issues/13033)).
> Verified working on Portainer 2.45.x.

To switch phase: set the env var, then **Stacks → homeassistant → Pull and
redeploy**.

## Architecture

```
Phase 1:   Caddy :443 → homeassistant:8123
                             ↓ (cloud)
                        Tuya servers → your Tuya Zigbee gateway → devices

Phase 2:   Caddy :443 → homeassistant:8123   (z2m.longie.net → zigbee2mqtt:8080)
                             ↓ MQTT
                        mosquitto:1883
                             ↑ MQTT
                        zigbee2mqtt  ──tcp://SLZB06:6638──→ SLZB-06 → Zigbee devices
```

Networks:
- `smarthome_net` — internal; HA ↔ mosquitto ↔ zigbee2mqtt
- `proxy_net` — external (owned by the caddy stack); Caddy reaches HA + Z2M by name

> **Deploy the caddy stack first** — it owns `proxy_net`. This stack won't start
> without it.

## DNS & Cloudflare

Each hostname needs a **Cloudflare DNS A record → `192.168.1.6` with the proxy
OFF (grey cloud)**, matching every other Caddy-proxied service (see the repo
[`ARCHITECTURE.md`](../../ARCHITECTURE.md)). Grey cloud means the record resolves
to the private IP, so the service is reachable only on the **LAN / Tailscale**.
Caddy issues TLS automatically via the DNS-01 challenge using the caddy stack's
`CLOUDFLARE_API_TOKEN`.

| Record | Add when | Points to |
|---|---|---|
| `homeassistant.longie.net` | Phase 1 (now) | A → `192.168.1.6`, grey cloud |
| `z2m.longie.net` | Phase 2 only | A → `192.168.1.6`, grey cloud |

> **Do not expose Home Assistant to the internet** (no Cloudflare Tunnel, no
> Access, no proxied/orange-cloud record). HA is a common attack target — keep it
> LAN-only. For remote access use Tailscale or the HA companion app over VPN.

`z2m.longie.net` is optional even in Phase 2 — it only serves the Zigbee2MQTT
admin UI. Skip the record if you reach Z2M another way (published port or an HA
iframe panel).

## Required env vars

Set in Portainer UI → stack → Environment variables.

| Variable | Phase | Notes |
|---|---|---|
| `DOCKER_DATA_HOME` | 1 & 2 | Host path for volumes (see repo README) |
| `COMPOSE_PROFILES` | 2 | Set to `zigbee` to enable Phase 2 |
| `SLZB06_HOST` | 2 | LAN IP of the SLZB-06 coordinator |
| `Z2M_AUTH_TOKEN` | 2 | Zigbee2MQTT frontend token — **secret**. Generate: `openssl rand -hex 32` |

> **Z2M frontend has no auth by default.** It is proxied at `z2m.longie.net`, so
> `Z2M_AUTH_TOKEN` is mandatory in Phase 2 — it protects full control of your
> Zigbee network.

## Phase 1 setup

1. Deploy the stack (no secrets needed). Open `http://192.168.1.6:8123`, create the
   owner account.
2. **Trust the Caddy reverse proxy** (else external requests return `400 Bad
   Request`). HA 2026.8+ configures this in the **UI, not YAML**: Settings → System
   → **Network** → **HTTP server** → turn on **Trust X-Forwarded-For** and add
   **Trusted proxies** `172.16.0.0/12` (docker / `proxy_net`) and `192.168.1.0/24`
   (LAN). Save, then restart HA.
   > On older HA this was an `http:` block in `configuration.yaml`. After the 2026.8
   > migration that block is **ignored** (raises a repair notice) — use the UI and
   > remove any `http:` block from `configuration.yaml`.
3. **Tuya integration:** Settings → Devices & Services → Add Integration → **Tuya**.
   No developer account needed (HA 2024.2+). In the Smart Life (or Tuya Smart) app:
   **Me → ⚙️ → Account and Security → User Code**; enter it in HA, then scan the QR
   HA shows using the app (**+ / Add Device → Scan**). Devices and TRVs import as
   `climate` / `sensor` entities. Added a device later? Add it in the app, then
   reload the Tuya integration in HA.

## Phase 2 setup (when the coordinator arrives)

1. Plug the SLZB-06 into the LAN, note its IP, confirm the Zigbee2MQTT TCP port in
   its web UI (default `6638`).
2. Set `COMPOSE_PROFILES=zigbee`, `SLZB06_HOST`, `Z2M_AUTH_TOKEN` in Portainer. Pull
   and redeploy. Confirm `mosquitto` and `zigbee2mqtt` containers appear.
3. Open `https://z2m.longie.net`, enable "Permit join".
4. **Migrate each device:** a Zigbee device joins one network at a time, so there's
   no bulk import. Factory-reset each TRV/sensor and pair it to the SLZB-06. They
   auto-discover into HA via MQTT.
5. Once everything is re-paired and working, remove the Tuya cloud integration from
   HA. The old Tuya gateway becomes a spare.

## Verify after deploy

```bash
# Phase 1
docker ps | grep homeassistant          # Up
# Phase 2
docker ps | grep -E "homeassistant|mosquitto|zigbee2mqtt"   # all Up
docker logs zigbee2mqtt | grep -i "connected to mqtt\|coordinator"
```

## Image tags & Watchtower

| Service | Tag | Watchtower |
|---|---|---|
| `homeassistant` | `:stable` | **excluded** — HA ships monthly breaking changes; upgrade deliberately |
| `zigbee2mqtt` | `:latest` | **excluded** — ships DB migrations + touches live Zigbee network |
| `mosquitto` | `:latest` | enabled (repo default; stable broker) |

Upgrade an excluded service via **Pull and redeploy**. This intentionally overrides
the repo's `:latest` + Watchtower default (same rationale as the `n8n` `stable`
exception).

## FAQ

**HA frontend looks broken behind Caddy.** The global `security_headers` CSP can
conflict with HA. Drop `import security_headers` from the `homeassistant.longie.net`
route in the caddy stack — HA sets its own headers.

**`z2m.longie.net` returns 502.** Expected in Phase 1 (service not running). It
works once `COMPOSE_PROFILES=zigbee` is set.

**Zigbee network key.** Auto-generated on first Z2M boot, stored in
`${DOCKER_DATA_HOME}/zigbee2mqtt`. **Back this volume up** — losing it means
re-pairing everything.

**MQTT has no auth.** The broker is only on the internal `smarthome_net` bridge
(never published to the LAN/host), so anonymous access is acceptable. Add a
username/password in `mosquitto.conf` if you ever expose it.
