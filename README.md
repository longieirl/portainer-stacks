# portainer-stacks

GitOps-managed Docker Compose stacks for Portainer.

## How it works

- Each stack lives in `stacks/<stack-name>/docker-compose.yml`
- Push to `main` → GitHub Actions fires Portainer webhook for changed stacks
- Watchtower pulls updated images nightly at 4am

## Wiring a stack to GitOps in Portainer

Delete the existing stack, then Stacks → **+ Add stack** → **Repository**:

| Field | Value |
|---|---|
| Repository URL | `https://github.com/longieirl/portainer-stacks.git` |
| Branch | `main` |
| Compose path | `stacks/<stack-name>/docker-compose.yml` |
| Authentication | Username + PAT |
| Username | `longieirl` |
| Token | github.com PAT with `repo` scope (starts with `ghp_` or `github_pat_`) |
| GitOps updates mechanism | **Webhook** (not Polling) |

After deploy, copy the webhook URL from the stack page → store as GitHub Actions secret `PORTAINER_WEBHOOK_<STACKNAME>`.

## Secrets

Never commit `.env` files. Real values live in Portainer's Environment Variables UI only.
See `.env.example` in each stack folder for required variables.

## Stack folder → GitHub Actions secret name mapping

Stack folder name is uppercased with hyphens replaced by underscores:
- `my-app` → `PORTAINER_WEBHOOK_MY_APP`
- `traefik` → `PORTAINER_WEBHOOK_TRAEFIK`

## Environment variables (host machine)

All volume paths in compose files use two env vars. Add both to `~/.zshrc`:

```bash
export DOCKER_DATA_HOME="${HOME}/Documents/docker/data"
export DOCKER_SHARED_HOME="${HOME}/Documents/docker/shared"
```

Or run the setup script: `bash scripts/setup-env.sh`

## Portainer stack environment variables

Portainer CE has no global env var injection — vars must be set **per stack** in the UI.

When wiring any stack via GitOps (Stacks → stack name → Editor → Environment variables), always add:

| Variable | Value |
|---|---|
| `DOCKER_DATA_HOME` | `/Users/longie/Documents/docker/data` |
| `DOCKER_SHARED_HOME` | `/Users/longie/Documents/docker/shared` |

Stacks that also need secrets:

| Stack | Additional vars |
|---|---|
| `gluetun` | `WIREGUARD_PRIVATE_KEY` |
| `n8n` | `POSTGRES_PASSWORD`, `N8N_ENCRYPTION_KEY` |

## Starting Portainer

Portainer is not managed as a stack — run it directly:

```bash
docker run -d \
  -p 8000:8000 \
  -p 9443:9443 \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v ${DOCKER_DATA_HOME}/portainer:/data \
  portainer/portainer-ce:latest
```

