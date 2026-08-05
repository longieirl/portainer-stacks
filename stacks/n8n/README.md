# n8n

Workflow automation. Backed by Postgres 16. Accessible at `https://n8n.longie.net`.

## Architecture

n8n runs on two networks:

- `n8n_net` — internal only; Postgres↔n8n communication, not reachable from outside
- `remote-access` — shared external network; Caddy can reach n8n by container name

A dedicated **Caddy stack** sits in front, terminating TLS and proxying traffic to n8n on port 5678. n8n is internet-facing via Cloudflare Tunnel — Cloudflare Access enforces authentication at the edge.

```
Internet → Cloudflare Tunnel → Caddy :443 → n8n:5678 (remote-access net)
                                                      ↓
                                            postgres:5432 (n8n_net, internal only)
```

**Why this approach instead of plain HTTP?**

- n8n stores OAuth tokens, API keys, and webhook secrets. These travel with every request — plain HTTP exposes them to anyone on the LAN who can sniff traffic.
- `N8N_SECURE_COOKIE=true` (required to protect session cookies from interception) only works over HTTPS.
- Cloudflare Access + Tunnel means zero open ports on the host for n8n — no direct inbound connections.
- PostgreSQL has no host port — only reachable within `n8n_net`, which is correct.

> **Deploy Caddy first.** The `remote-access` network is owned by the caddy stack. n8n will fail to start if it doesn't exist yet.

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

**3. n8n UI loads:**

Open `https://n8n.longie.net` — should reach the n8n login screen.

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

## Webhook security

`n8n.longie.net/webhook/*` is bypassed in Cloudflare Access — these paths are publicly reachable without GitHub OAuth. Each webhook that accepts external calls must validate the request source at the application level.

### GitHub webhooks — HMAC signature validation

Add a **Code** node as the first node in any GitHub-triggered workflow:

```javascript
const crypto = require('crypto');

const secret = $env.GITHUB_WEBHOOK_SECRET;
const payload = JSON.stringify($input.first().json);
const signature = $input.first().headers['x-hub-signature-256'];

if (!signature) throw new Error('Missing X-Hub-Signature-256 header');

const expected = 'sha256=' + crypto
  .createHmac('sha256', secret)
  .update(payload)
  .digest('hex');

if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
  throw new Error('Invalid signature — request rejected');
}

return $input.all();
```

Set `GITHUB_WEBHOOK_SECRET` in Portainer UI → n8n stack → Environment variables (generate with `openssl rand -hex 32`). Set the same value in GitHub: repo → Settings → Webhooks → your webhook → Secret.

### Generic webhooks

In the n8n Webhook trigger node: Authentication → Header Auth → Header name: `X-Webhook-Secret` → Value: a random secret stored in Portainer env.

### Audit checklist

- [ ] Every workflow with a Webhook trigger node has signature validation as first node
- [ ] `/webhook-test/*` bypass removed from Cloudflare Access policy when not actively developing
- [ ] Each webhook secret stored in Portainer UI (never in git)
