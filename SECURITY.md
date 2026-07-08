# Security Policy

## Scope

This repository contains Docker Compose configuration files for self-hosted services
running on a private home network. It does not contain application code or handle
public user data.

## Reporting a vulnerability

If you find a security issue in this repository — for example, a committed secret,
an insecure default in a compose file, or a workflow that could be exploited — please
report it privately rather than opening a public GitHub issue.

**Report via:** [GitHub Security Advisory](https://github.com/longieirl/portainer-stacks/security/advisories/new)
via the Security tab of this repository.

Include:
- What you found
- Which file or configuration is affected
- Why it is a risk
- A suggested fix if you have one

You will receive a response within 5 business days. There is no bug bounty program.

## Supported versions

Only the `main` branch is actively maintained.

## Push protection bypass policy

Secret scanning push protection can be bypassed by users with write access. This is not
permitted unless the detected secret is a confirmed false positive. Any bypass must be
reviewed by the repository owner. Bypass events are logged in the repository audit log.

## TLS strategy

All services run on a private LAN. The threat model is credential interception by another device on the same network, not external attack. The following decisions reflect that:

### Decision table

| Service | Approach | Reason |
|---|---|---|
| **n8n** | HTTPS via Caddy reverse proxy | Stores OAuth tokens and API keys; `N8N_SECURE_COOKIE=true` requires HTTPS |
| **Sonarr** | HTTPS via Caddy reverse proxy | No native TLS; co-located with n8n behind the same Caddy instance — zero extra overhead |
| **qBittorrent** | HTTPS via Caddy reverse proxy | Uses `network_mode: container:gluetun` — no independent network; Caddy reaches it via gluetun on `proxy_net`; port 8080 removed from host |
| **Jackett** | Plain HTTP, accepted risk | No native TLS, no proxy; API key only used by internal containers; low exposure on trusted LAN |
| **Deluge** | Plain HTTP, accepted risk | No native TLS; WebUI accessed infrequently; acceptable on trusted LAN |
| **FlareSolverr** | Plain HTTP, accepted risk | Container-to-container only; not user-facing; TLS adds no practical benefit |
| **Portainer** | HTTPS by default (port 9443) | Ships with self-signed cert out of the box |
| **PostgreSQL (n8n)** | Plain TCP, accepted risk | Internal container network only; not reachable from host or LAN |

### Caddy reverse proxy

Caddy in `stacks/caddy/` uses DNS-01 ACME challenge via Cloudflare to issue real Let's Encrypt certificates for `*.longie.net` subdomains. All LAN services are proxied via named subdomains. n8n is exposed publicly via Cloudflare Tunnel — no inbound router ports required.

### If the homelab grows

Once three or more web applications are running, routing all of them through Caddy is simpler than managing per-service TLS. To add a new service: add a block to the Caddyfile in `stacks/caddy/docker-compose.yml` and redeploy the caddy stack.

### What is intentionally out of scope

- Database encryption in transit (Postgres): internal network, single-user, not worth the operational cost
- Docker daemon TLS: out of scope for this repository
- mTLS between containers: not warranted for a single-user homelab

## Known accepted risks

The following patterns exist intentionally and are documented here:

| Pattern | File | Reason |
|---|---|---|
| `/var/run/docker.sock` mount | `stacks/watchtower/docker-compose.yml` | Watchtower requires Docker socket to manage containers |
| `cap_add: NET_ADMIN` | `stacks/gluetun/docker-compose.yml` | Required for WireGuard VPN tunnel |
| `/dev/net/tun` device | `stacks/gluetun/docker-compose.yml` | Required for WireGuard VPN tunnel |
| `:latest` image tags | all stacks except n8n | Intentional — Watchtower manages updates |
| Hostnames and LAN IP in compose files | `stacks/caddy/docker-compose.yml`, `stacks/n8n/docker-compose.yml` | `longie.net` subdomains and `192.168.1.6` are visible in this public repo. Accepted risk: the domain is publicly queryable via WHOIS and DNS regardless; `192.168.1.6` is an RFC1918 private address unreachable from the internet. This is information disclosure (reveals which services are running) but not exploitable for this threat model. |
| `cap_add: NET_BIND_SERVICE` | `stacks/caddy/docker-compose.yml` | Required for Caddy to bind ports 80/443 as non-root |
| `cap_add: CHOWN, SETUID, SETGID, DAC_OVERRIDE, FOWNER` | `stacks/n8n/docker-compose.yml` (postgres) | Required for PostgreSQL data directory ownership with `cap_drop: ALL` |
