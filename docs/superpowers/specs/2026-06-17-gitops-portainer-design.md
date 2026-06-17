# GitOps Portainer Stacks — Design Spec

**Date:** 2026-06-17  
**Status:** Approved

## Goal

Private GitHub repo tracking all Docker Compose stacks managed by Portainer. Push to `main` triggers redeploy of changed stacks via Portainer webhooks. Watchtower handles nightly image pulls independently.

---

## Repo Structure

```
portainer-stacks/
  stacks/
    <stack-name>/
      docker-compose.yml       # versioned compose, no secrets
      .env.example             # documents required vars, safe to commit
  .gitignore
  README.md
  .github/
    workflows/
      deploy.yml               # fires Portainer webhooks on push
```

**Conventions:**
- Stack folder name = Portainer stack name (exact match)
- `image:` tags use `repo/image:latest` — Watchtower handles pulls, no pinning
- All secrets referenced as `${VAR_NAME}` — actual `.env` lives on server only
- `main` = production; no staging branch until second server exists

---

## Portainer GitOps Wiring

Each Portainer stack configured as "Git repository" type:

| Field | Value |
|---|---|
| Repository URL | `https://github.com/<org>/portainer-stacks` |
| Branch | `main` |
| Compose path | `stacks/<stack-name>/docker-compose.yml` |
| Auth | Single read-only deploy key (SSH) |
| Auto-update | OFF (webhook-driven) |

**Deploy flow:**
```
git push main
  → GitHub Actions (deploy.yml)
    → detects changed stacks via path filter
    → POST to Portainer webhook URL per changed stack
      → Portainer pulls compose from repo
      → docker compose up -d --remove-orphans
```

Each stack's Portainer webhook URL stored as a GitHub Actions secret (`PORTAINER_WEBHOOK_<STACKNAME>`).

---

## Watchtower Stack

Lives at `stacks/watchtower/docker-compose.yml`. Deployed via same GitOps flow.

```yaml
services:
  watchtower:
    image: containrrr/watchtower:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_STOPPED=false
      - WATCHTOWER_SCHEDULE=0 0 4 * * *
```

- Watches all containers by default
- Opt out per-service: label `com.centurylinklabs.watchtower.enable=false`
- Fires nightly at 4am, restarts containers with new image digest

---

## Secrets Handling

**In git (safe):**
- `docker-compose.yml` — env var references only (`${VAR_NAME}`)
- `.env.example` — placeholder values + comments, committed

**In Portainer (never in git):**
- Each GitOps stack has an "Environment variables" section in the Portainer UI
- Set real values there — Portainer stores them in its own database, injects at deploy time
- Do NOT use `env_file:` in compose — Portainer clones the repo to a temp dir where no `.env` exists

**`.gitignore`:**
```
.env
.env.*
*.env
!.env.example
```

**Deploy key:** Single read-only SSH key pair. Public key added to GitHub repo (Settings → Deploy keys). Private key stored on server, referenced in Portainer git auth config.

**Portainer webhook URLs:** Stored as GitHub Actions secrets (not in repo files).

---

## GitHub Actions Workflow

`deploy.yml` runs on push to `main`. Uses path filters so only stacks with changed files trigger a webhook call.

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'stacks/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2
      - name: Detect changed stacks and trigger webhooks
        run: |
          changed=$(git diff --name-only HEAD~1 HEAD -- stacks/ \
            | cut -d/ -f2 | sort -u)
          for stack in $changed; do
            secret_name="PORTAINER_WEBHOOK_$(echo $stack | tr '[:lower:]-' '[:upper:]_')"
            url="${{ secrets[secret_name] }}"
            if [ -n "$url" ]; then
              echo "Deploying $stack"
              curl -s -X POST "$url"
            fi
          done
```

---

## Migration Plan (existing stacks)

1. Create GitHub repo (`portainer-stacks`, private)
2. Add deploy key to repo
3. For each existing Portainer stack:
   - Export compose YAML from Portainer UI
   - Create `stacks/<name>/docker-compose.yml`
   - Create `stacks/<name>/.env.example` from current env vars (strip values)
   - Commit and push
   - Reconfigure stack in Portainer to point at git repo
   - Get webhook URL, store as GitHub Actions secret
4. Deploy Watchtower stack last
5. Verify end-to-end: push a whitespace change, confirm webhook fires and stack redeploys

---

## Out of Scope

- Multi-environment (staging/prod split) — revisit if second server added
- Image tag pinning / Renovate PRs — Watchtower covers auto-updates
- Encrypted secrets in repo (SOPS/git-crypt) — server-side `.env` sufficient
