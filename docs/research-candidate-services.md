# Candidate Self-Hosted Services

Research notes on services evaluated for potential inclusion in this stack. Each entry covers purpose, Docker considerations, complexity, and fit with the existing setup (Caddy reverse proxy, Cloudflare Tunnel, Watchtower, Portainer CE GitOps).

---

## Pi-hole

**Purpose:** Network-wide DNS-level ad and tracker blocking, optional DHCP server.

**Docker considerations:**

- Requires port `53` (TCP + UDP) for DNS. On many Linux hosts this port is held by `systemd-resolved` and must be disabled or reconfigured before Pi-hole can bind to it.
- For LAN-wide blocking, the host's IP must be set as the DNS server on your router. Without this, only containers on the same Docker network benefit.
- `network_mode: host` is the recommended mode for DNS functionality; bridge mode with port mapping works but can cause issues with DNS source IP detection.

| | |
|---|---|
| Pros | Network-wide blocking for all devices (phones, TVs, consoles), DHCP management, good admin UI, well-documented |
| Cons | Port 53 conflict common on modern Linux, requires router-level DNS config change, `host` network mode recommended which reduces container isolation |

**Complexity:** Medium. Single container, but network setup requires host-level changes.

---

## Home Assistant

**Purpose:** Local home automation hub. Integrates smart devices, sensors, and services into a unified platform with automations and dashboards.

**Docker considerations:**

- Runs on port `8123`. Straightforward to put behind Caddy.
- USB hardware (Zigbee/Z-Wave dongles) requires device passthrough (`devices:` in compose or `privileged: true`). Works well on Linux hosts with direct hardware access.
- No USB hardware required if using only network-based integrations (WiFi devices, IP cameras, cloud connectors).
- Integrates well with Frigate (cameras), n8n (automations), and MQTT brokers.

| | |
|---|---|
| Pros | Massive integration ecosystem (3000+ integrations), local-first, active community, strong automation engine, good Caddy/Cloudflare Tunnel candidate |
| Cons | `privileged: true` or device passthrough needed for USB hardware, large image, can be resource-heavy with many integrations |

**Complexity:** Medium. Single container for software-only use; grows with hardware integrations.

---

## Frigate

**Purpose:** Local NVR (network video recorder) with real-time AI object detection (persons, vehicles, animals) for IP cameras.

**Docker considerations:**

- Designed to run alongside Home Assistant; integrates via MQTT and the Home Assistant Frigate integration.
- Hardware acceleration strongly recommended: supports NVIDIA CUDA, Intel QSV/VAAPI, AMD ROCM, Google Coral TPU, Raspberry Pi GPU. CPU-only mode works but is resource-intensive at scale.
- Requires a hardware accelerator passthrough (`devices:` in compose) for GPU/Coral use.
- Storage-heavy: retains video clips and snapshots on disk.
- Exposes a web UI (port `5000`) and RTSP streams.

| | |
|---|---|
| Pros | Fully local AI detection (no cloud), excellent Home Assistant integration, privacy-first, active development |
| Cons | Needs GPU or Coral TPU for efficient detection at scale, storage requirements grow with camera count and retention period, complex configuration |

**Complexity:** High. Config-heavy, hardware-dependent for good performance, pairs with Home Assistant.

---

## Mealie

**Purpose:** Self-hosted recipe manager and meal planner with recipe scraping from URLs.

**Docker considerations:**

- Single container with SQLite (default) or PostgreSQL. No external dependencies required for basic use.
- Runs on port `9000` by default.
- Straightforward Caddy reverse proxy candidate.
- Low resource footprint.

| | |
|---|---|
| Pros | Clean UI, one-click recipe import from most cooking sites, meal planning, shopping list generation, active development, REST API |
| Cons | No significant drawbacks for this setup |

**Complexity:** Low. Single container, minimal config.

---

## Paperless-ngx

**Purpose:** Document management system with OCR. Scans, indexes, and tags documents for searchable storage.

**Docker considerations:**

- Multi-container stack: app + Redis + PostgreSQL + optionally Gotenberg (Office/HTML to PDF) and Tika (document content extraction).
- OCR is handled by Tesseract (bundled). CPU-bound but not continuous — only triggers on document ingest.
- Supports automated email ingestion (IMAP polling) and folder-based consumption.
- Storage grows proportionally with document volume.
- Follows same pattern as the existing n8n stack (app + Postgres).

| | |
|---|---|
| Pros | Excellent OCR quality, powerful tagging and correspondent system, email ingestion, full-text search, REST API, active development |
| Cons | Heavier stack (3-5 containers), initial bulk import of large document collections is slow, storage grows continuously |

**Complexity:** High. Multi-service stack, similar in footprint to n8n.

---

## Homebox

**Purpose:** Home inventory management. Track physical items, locations, warranties, purchase records.

**Docker considerations:**

- Single container, SQLite only. Minimal resource use.
- Runs on port `7745` by default.
- No external dependencies.

| | |
|---|---|
| Pros | Very lightweight, simple to deploy, useful for home item/warranty tracking |
| Cons | Less mature project than others on this list, limited integrations, narrower use case |

**Complexity:** Low. Single container, zero config.

---

## Scrutiny

**Purpose:** S.M.A.R.T. monitoring dashboard for hard drives. Tracks drive health, temperature history, and failure indicators.

**Docker considerations:**

- Requires direct access to host block devices (`/dev/sda`, `/dev/nvme0n1`, etc.) mounted into the container.
- Works on Linux hosts where Docker can access block devices natively. Does not work on hosts where Docker runs inside a VM (the VM's virtual disks are visible, not the underlying physical drives).
- Collects metrics via `smartmontools` running inside the container (or as a separate collector sidecar for multi-host setups).
- Stores history in InfluxDB (bundled in the all-in-one image).

| | |
|---|---|
| Pros | Clean dashboard, drive health history, failure prediction, multi-host collector support, lightweight |
| Cons | Requires direct block device access — does not work where Docker runs in a VM layer; limited value without physical drive visibility |

**Complexity:** Low on Linux. Setup is trivial if block devices are accessible.

---

## Summary

| Service | Complexity | Notable Dependency | Immediate Value |
|---|---|---|---|
| Pi-hole | Medium | Port 53 + router DNS config | High |
| Home Assistant | Medium | USB hardware (optional) | High |
| Frigate | High | GPU/Coral + Home Assistant | Medium |
| Mealie | Low | None | Medium |
| Paperless-ngx | High | Redis + PostgreSQL + Gotenberg/Tika | High |
| Homebox | Low | None | Low–Medium |
| Scrutiny | Low | Direct block device access | Zero without it |

**Recommended addition order** if adding any: Mealie (trivial, no risk) → Paperless-ngx (highest utility, proven pattern) → Home Assistant (if smart devices present) → Pi-hole (requires host-level network changes, plan carefully).
