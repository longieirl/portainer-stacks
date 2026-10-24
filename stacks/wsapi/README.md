# wsapi

WhatsApp API gateway. Listens on `127.0.0.1:8080` (localhost only — not accessible from LAN or external). Runs in multi-instance mode with webhook event delivery.

## Architecture

Bound to loopback only — no external exposure. Runs on an isolated `wsapi_net` bridge network. Other services call it via the host loopback or from within `wsapi_net`.

```
Internal caller → 127.0.0.1:8080 → wsapi:8080
```

## Required environment variables

Set in Portainer UI → stack → Environment variables:

| Variable | Notes |
|---|---|
| `DOCKER_DATA_HOME` | Host path for wsapi data (SQLite DB) |
| `WSAPI_ADMIN_API_KEY` | Admin API key for instance management |
| `WSAPI_DEFAULT_API_KEY` | Default API key for message sending |
| `WSAPI_DEFAULT_WEBHOOK_URL` | Webhook URL for inbound event delivery |

Optional overrides (defaults shown):

| Variable | Default | Notes |
|---|---|---|
| `WSAPI_DB_DRIVER` | `sqlite` | Use `postgres` for production |
| `WSAPI_DB_DSN` | `./data/wsapi.db` | DB path or connection string |
| `WSAPI_LOG_LEVEL` | `info` | `debug`, `info`, `warn`, `error` |
| `WSAPI_LOG_FORMAT` | `text` | `text` or `json` |

## Verify after deploy

**1. Container running:**
```bash
docker ps | grep wsapi
```

**2. Health check passing:**
```bash
curl http://localhost:8080/health
```
Expected: `200 OK`.
