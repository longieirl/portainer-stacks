# n8n

Workflow automation. Backed by Postgres 16. Accessible at `https://192.168.1.6`.

## Architecture

n8n runs on two networks:

- `n8n_net` — internal only; Postgres↔n8n communication, not reachable from outside
- `proxy_net` — shared external network; Caddy can reach n8n by container name

A dedicated **Caddy stack** sits in front of all proxied services. It terminates TLS and proxies traffic to n8n on port 5678 over the internal Docker network.

```
Browser → Caddy :443 (HTTPS, tls internal) → n8n:5678 (proxy_net)
                                                       ↓
                                             postgres:5432 (n8n_net, internal only)
```

**Why this approach instead of plain HTTP or native n8n SSL?**

- n8n stores OAuth tokens, API keys, and webhook secrets. These travel with every request — plain HTTP exposes them to anyone on the LAN who can sniff traffic.
- `N8N_SECURE_COOKIE=true` (required to protect session cookies from interception) only works over HTTPS. Without it, sessions can be hijacked on the local network.
- Caddy's `tls internal` generates a local CA automatically — no manual cert creation, no renewal management.
- Sharing one Caddy instance across stacks (n8n, Sonarr) is simpler than running a proxy per service.
- PostgreSQL has no host port — it is only reachable within `n8n_net`, which is correct.

> **Deploy Caddy first.** The `proxy_net` network is owned by the caddy stack. n8n and Sonarr declare it as `external: true` and will fail to start if it doesn't exist yet.

## Required secrets

Set in Portainer UI → stack → Environment variables:

| Variable | Notes |
|---|---|
| `POSTGRES_PASSWORD` | Same value used by both postgres and n8n services |
| `N8N_ENCRYPTION_KEY` | Encrypts saved credentials — find existing key in `DOCKER_DATA_HOME/n8n_data/.n8n/config` under `encryptionKey` |

> **Important:** `N8N_ENCRYPTION_KEY` must match the value already stored in the config file. Changing it will break all saved credentials in n8n.

## Verify after deploy

**1. All containers healthy:**
```bash
docker ps | grep -E "n8n|postgres"
```
Expected: `n8n` and `n8n-postgres` both show `healthy` or `Up`.

**2. Postgres accepting connections:**
```bash
docker exec n8n-postgres pg_isready -U n8n -d n8n
```
Expected: `n8n:5432 - accepting connections`

**3. n8n UI loads over HTTPS:**

Open `https://192.168.1.6` — should reach the n8n login screen. See the Caddy stack README for CA trust setup.

**4. Encryption key correct:**

Log in and open any workflow that uses saved credentials. If credentials show as broken/unreadable, the `N8N_ENCRYPTION_KEY` doesn't match the config file value.

## FAQ

**n8n unreachable after deploy:**

Check Caddy logs — it is the entry point:
```bash
docker logs caddy
```

**Forgot password / can't log in:**
```bash
docker exec n8n n8n user-management:reset
```
Resets the owner account — you'll be prompted to create a new one on next login. Workflows and data stay intact.
