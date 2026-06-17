# n8n

Workflow automation. Backed by Postgres 16. Accessible at `http://192.168.1.6:5678`.

## Required secrets

Set in Portainer UI → stack → Environment variables:

| Variable | Notes |
|---|---|
| `POSTGRES_PASSWORD` | Same value used by both postgres and n8n services |
| `N8N_ENCRYPTION_KEY` | Encrypts saved credentials — find existing key in `/Users/longie/Documents/docker/data/n8n_data/.n8n/config` under `encryptionKey` |

> **Important:** `N8N_ENCRYPTION_KEY` must match the value already stored in the config file. Changing it will break all saved credentials in n8n.

## Notes

- `N8N_SECURE_COOKIE=false` is set in the compose file — required for HTTP access on a local network. n8n's secure cookie default blocks access over plain HTTP (and in Safari).

## Verify after deploy

**1. Both containers healthy:**
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

Open `http://192.168.1.6:5678` — should reach the n8n login screen.

**4. Encryption key correct:**

Log in and open any workflow that uses saved credentials. If credentials show as broken/unreadable, the `N8N_ENCRYPTION_KEY` doesn't match the config file value.

## FAQ

**Forgot password / can't log in:**
```bash
docker exec n8n n8n user-management:reset
```
Resets the owner account — you'll be prompted to create a new one on next login. Workflows and data stay intact.
