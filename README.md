# portainer-stacks

GitOps-managed Docker Compose stacks for Portainer.

> Inspired by [self-hosted-cookbook](https://github.com/tborychowski/self-hosted-cookbook) — a great reference for discovering and configuring self-hosted Docker Compose services.

## How it works

- Each stack lives in `stacks/<stack-name>/docker-compose.yml`
- Push to `main` → GitHub Actions validates compose syntax for changed stacks
- Portainer polls this repo every 24h and redeploys any stack whose compose file changed
- Watchtower pulls updated images nightly at 4am

> **Why polling, not webhooks?**
> Portainer runs on a private LAN (`192.168.1.6`). GitHub Actions runners are hosted externally (Azure) and cannot reach private IP addresses. Webhook calls time out with exit code 28. Polling works for now. More advanced options (Cloudflare Tunnel, self-hosted runner, port forwarding + DDNS) would enable webhook-based instant deploys if needed later.

---

## New developer setup checklist

### 1. Host machine env vars

Add to `~/.zshrc` (or run `bash scripts/setup-env.sh`):

```bash
export DOCKER_DATA_HOME="${HOME}/Documents/docker/data"
export DOCKER_SHARED_HOME="${HOME}/Documents/docker/shared"
```

Create directories:

```bash
mkdir -p "${DOCKER_DATA_HOME}" "${DOCKER_SHARED_HOME}"
```

### 2. Start Portainer

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

Access at `https://localhost:9443`.

### 3. Wire each stack to GitOps in Portainer

Delete the existing stack, then Stacks → **+ Add stack** → **Repository**:

| Field | Value |
|---|---|
| Repository URL | `https://github.com/longieirl/portainer-stacks.git` |
| Branch | `main` |
| Compose path | `stacks/<stack-name>/docker-compose.yml` |
| Authentication | Username + PAT |
| Username | `longieirl` |
| Token | github.com PAT with `repo` scope (starts with `ghp_` or `github_pat_`) |
| GitOps updates mechanism | **Polling** (NOT Webhook — see note above) |
| Polling interval | `24h` |
| Re-pull image | OFF (Watchtower handles image updates) |

After saving, confirm the stack shows "GitOps updates: Polling" on the stack page.

### 4. Set environment variables per stack in Portainer UI

Portainer CE has no global env var injection — vars must be set **per stack** in the UI.

> **Note:** GitOps-managed stacks have no compose editor in Portainer CE — the compose is locked to git and cannot be edited via the UI. To force-redeploy immediately (e.g. after port mapping changes), use Stacks → stack name → **"Pull and redeploy"**.

Stacks → stack name → **Environment variables** tab, add:

| Variable | Value |
|---|---|
| `DOCKER_DATA_HOME` | `/Users/longie/Documents/docker/data` |
| `DOCKER_SHARED_HOME` | `/Users/longie/Documents/docker/shared` |

Stacks that also need secrets:

| Stack | Additional vars |
|---|---|
| `gluetun` | `WIREGUARD_PRIVATE_KEY` |
| `n8n` | `POSTGRES_PASSWORD`, `N8N_ENCRYPTION_KEY` |

### 5. Verify end-to-end

- [ ] All 7 stacks running in Portainer: gluetun, deluge, jackett, qbittorrent, sonarr, n8n, watchtower
- [ ] Each stack shows GitOps source pointing to this repo
- [ ] Each stack has polling set to 24h
- [ ] `DOCKER_DATA_HOME` and `DOCKER_SHARED_HOME` set in each stack's Environment Variables tab
- [ ] gluetun, n8n have their secret vars set
- [ ] Push a trivial change to any stack → GitHub Actions "Validate changed stacks" passes (green)
- [ ] Wait for or manually trigger a Portainer poll → stack redeploys from git
- [ ] Verify Watchtower nightly run (runs 04:00 UTC): `docker logs watchtower --since 24h` — check `Session done` line shows `Failed=0` and no API errors

---

## Stack dependency order

gluetun **must be running** before starting deluge, jackett, or qbittorrent — all three use `network_mode: container:gluetun`.

---

## Secrets

Never commit `.env` files. Real values live in Portainer's Environment Variables UI only.
See `.env.example` in each stack folder for required variables.

---

## Environment variables (host machine)

All volume paths in compose files use two env vars. Add both to `~/.zshrc`:

```bash
export DOCKER_DATA_HOME="${HOME}/Documents/docker/data"
export DOCKER_SHARED_HOME="${HOME}/Documents/docker/shared"
```

Or run the setup script: `bash scripts/setup-env.sh`

---

## License

[MIT](LICENSE)
