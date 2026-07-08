# portainer-stacks

GitOps-managed Docker Compose stacks for a Portainer CE instance running on macOS.

## Structure

```
stacks/         One folder per stack, each with docker-compose.yml and .env.example
scripts/        Host setup scripts
.github/        GitHub Actions workflow and CODEOWNERS
```

## Stack

- Portainer CE (Community Edition) on macOS
- Docker Compose (no Swarm, no Kubernetes)
- GitHub Actions for compose validation on push/PR
- Watchtower for nightly image auto-updates
- GitOps via Portainer polling (24h) — webhooks don't work with LAN-hosted Portainer

## Key URLs

- Repo: https://github.com/longieirl/portainer-stacks
- Portainer: https://portainer.longie.net (LAN only — proxied via Caddy)
- n8n: https://n8n.longie.net (via Cloudflare Tunnel)

## Git Conventions

Commit format: `type: description`

Types: `feat` | `fix` | `perf` | `chore` | `docs` | `refactor` | `test`

Branch naming: `type/short-description` (e.g. `fix/gluetun-subnet`, `feat/new-stack`)

If working on a GitHub issue, include the issue ID: `type/123-short-description`

Never push directly to `main`. Always work on a branch. PRs required — CODEOWNERS can self-merge with 0 reviews.

## Safety Rules

- Flag security issues before any other recommendation
- Never commit secrets, credentials, or private keys
- Before making any change, verify it will work — check current docs if uncertain
- Never modify production stacks without explicit instruction

## Domain Rules

- Stack folder name must exactly match the Portainer stack name
- `image:` tags use `:latest` — Watchtower handles updates, no pinning. Exception: `n8n` uses `stable` tag (internet-facing service).
- No secrets in git — real values set in Portainer's Environment Variables UI per stack
- `.env.example` per stack documents all required vars
- `DOCKER_DATA_HOME` and `DOCKER_SHARED_HOME` must be set in Portainer UI for every stack (CE has no global env var injection)
- `stack.env` files must not be committed — they would expose host paths when repo goes public
- Portainer is started manually via `docker run` (see README) — it is not a managed stack
- Never use `privileged: true` unless strictly required and documented why
- gluetun must be running before deluge, jackett, and qbittorrent (all use `network_mode: container:gluetun`)
- GitOps-managed stacks have **no compose editor** in Portainer CE UI — compose is locked to git; all changes go through git + PR. To force-redeploy immediately (e.g. after port mapping changes): Stacks → stack name → "Pull and redeploy"

## Secrets reference

| Stack | Secret vars (Portainer UI only) |
|---|---|
| gluetun | `WIREGUARD_PRIVATE_KEY` |
| n8n | `POSTGRES_PASSWORD`, `N8N_ENCRYPTION_KEY`, `CLOUDFLARE_TUNNEL_TOKEN` |
| caddy | `CLOUDFLARE_API_TOKEN` |
