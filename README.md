# portainer-stacks

GitOps-managed Docker Compose stacks for Portainer.

## How it works

- Each stack lives in `stacks/<stack-name>/docker-compose.yml`
- Push to `main` → GitHub Actions fires Portainer webhook for changed stacks
- Watchtower pulls updated images nightly at 4am

## Adding a new stack

1. Create `stacks/<stack-name>/docker-compose.yml`
2. Create `stacks/<stack-name>/.env.example` documenting all required vars
3. In Portainer: create stack → Git repository → point at this repo
4. Copy the Portainer webhook URL
5. Add GitHub Actions secret: `PORTAINER_WEBHOOK_<STACKNAME>` (uppercase, hyphens → underscores)
6. In `.github/workflows/deploy.yml`, add to the `env:` block:
   `PORTAINER_WEBHOOK_<STACKNAME>: ${{ secrets.PORTAINER_WEBHOOK_<STACKNAME> }}`
7. In Portainer: set real env var values under the stack's Environment Variables tab

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

