# GitOps Portainer Stacks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a private GitHub repo at `github.com/longieirl/portainer-stacks` that tracks all Portainer Docker Compose stacks, deploys on push via Portainer webhooks, and auto-updates images nightly via Watchtower.

**Architecture:** Monorepo with `stacks/<name>/docker-compose.yml` per stack. Push to `main` triggers GitHub Actions which detects changed stack folders and fires the matching Portainer webhook. Watchtower runs as its own managed stack. Secrets live in Portainer's UI, never in git.

**Tech Stack:** GitHub (private repo, `github.com`), GitHub Actions, Portainer GitOps webhook mode, Docker Compose, Watchtower `containrrr/watchtower:latest`

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `.gitignore` | Create | Block `.env` files from git |
| `README.md` | Create | How to add stacks, how deploy works |
| `.github/workflows/deploy.yml` | Create | Detects changed stacks, fires Portainer webhooks |
| `stacks/watchtower/docker-compose.yml` | Create | Watchtower stack definition |
| `stacks/watchtower/.env.example` | Create | Documents watchtower env vars |
| `stacks/<name>/docker-compose.yml` | Create (×N) | One per existing Portainer stack |
| `stacks/<name>/.env.example` | Create (×N) | Env var documentation per stack |

---

### Task 1: Initialize git repo and create GitHub private repo

**Files:** none (git init + remote setup)

- [ ] **Step 1: Initialize git in the working directory**

```bash
cd /Users/I313149/Library/CloudStorage/Dropbox/work/ClaudeWebsites/portainer.io
git init
git checkout -b main
```

Expected: `Initialized empty Git repository in .../portainer.io/.git/`

- [ ] **Step 2: Create private repo on github.com**

```bash
gh repo create portainer-stacks \
  --hostname github.com \
  --private \
  --description "Portainer Docker Compose stacks — GitOps managed" \
  --source . \
  --remote origin
```

Expected: URL printed — `https://github.com/longieirl/portainer-stacks`

- [ ] **Step 3: Verify remote set correctly**

```bash
git remote -v
```

Expected output contains:
```
origin  git@github.com:longieirl/portainer-stacks.git (fetch)
origin  git@github.com:longieirl/portainer-stacks.git (push)
```

---

### Task 2: Create .gitignore

**Files:**
- Create: `.gitignore`

- [ ] **Step 1: Write .gitignore**

Create `.gitignore` with this exact content:

```gitignore
# Never commit real env files
.env
.env.*
*.env
!.env.example

# OS noise
.DS_Store
Thumbs.db
```

- [ ] **Step 2: Verify .env.example would NOT be blocked**

```bash
git check-ignore -v stacks/test/.env.example 2>&1
```

Expected: no output (not ignored). If output appears, the negation rule `!.env.example` is missing — re-check the file.

---

### Task 3: Create README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README.md**

Create `README.md`:

```markdown
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
6. In Portainer: set real env var values under the stack's Environment Variables tab

## Secrets

Never commit `.env` files. Real values live in Portainer's Environment Variables UI only.
See `.env.example` in each stack folder for required variables.

## Stack folder → GitHub Actions secret name mapping

Stack folder name is uppercased with hyphens replaced by underscores:
- `my-app` → `PORTAINER_WEBHOOK_MY_APP`
- `traefik` → `PORTAINER_WEBHOOK_TRAEFIK`
```

---

### Task 4: Create GitHub Actions deploy workflow

**Files:**
- Create: `.github/workflows/deploy.yml`

- [ ] **Step 1: Create workflows directory**

```bash
mkdir -p .github/workflows
```

- [ ] **Step 2: Write deploy.yml**

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy changed stacks

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

          if [ -z "$changed" ]; then
            echo "No stack folders changed, skipping."
            exit 0
          fi

          for stack in $changed; do
            secret_name="PORTAINER_WEBHOOK_$(echo "$stack" | tr '[:lower:]-' '[:upper:]_')"
            url=$(printenv "$secret_name" || true)
            if [ -z "$url" ]; then
              echo "WARNING: No webhook secret found for $stack (expected $secret_name) — skipping"
              continue
            fi
            echo "Triggering deploy for: $stack"
            http_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$url")
            if [ "$http_code" != "200" ] && [ "$http_code" != "204" ]; then
              echo "ERROR: Webhook for $stack returned HTTP $http_code"
              exit 1
            fi
            echo "$stack deploy triggered OK (HTTP $http_code)"
          done
        env:
          PORTAINER_WEBHOOK_WATCHTOWER: ${{ secrets.PORTAINER_WEBHOOK_WATCHTOWER }}
          # Add one line per stack — see README for naming convention
```

> **Note:** The `env:` block must list each secret explicitly — GitHub Actions does not support dynamic secret lookup by name at runtime. Add one `PORTAINER_WEBHOOK_<STACKNAME>: ${{ secrets.PORTAINER_WEBHOOK_<STACKNAME> }}` line per stack as you add them.

- [ ] **Step 3: Verify YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/deploy.yml'))" && echo "YAML OK"
```

Expected: `YAML OK`

---

### Task 5: Create Watchtower stack

**Files:**
- Create: `stacks/watchtower/docker-compose.yml`
- Create: `stacks/watchtower/.env.example`

- [ ] **Step 1: Create directory**

```bash
mkdir -p stacks/watchtower
```

- [ ] **Step 2: Write docker-compose.yml**

Create `stacks/watchtower/docker-compose.yml`:

```yaml
services:
  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_STOPPED=false
      - WATCHTOWER_SCHEDULE=0 0 4 * * *
      - WATCHTOWER_NOTIFICATIONS=${WATCHTOWER_NOTIFICATIONS:-}
      - WATCHTOWER_NOTIFICATION_URL=${WATCHTOWER_NOTIFICATION_URL:-}
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
```

- [ ] **Step 3: Write .env.example**

Create `stacks/watchtower/.env.example`:

```bash
# Optional: notification backend (email/slack/generic webhook)
# See https://containrrr.dev/watchtower/notifications/
WATCHTOWER_NOTIFICATIONS=
WATCHTOWER_NOTIFICATION_URL=
```

---

### Task 6: Initial commit and push

- [ ] **Step 1: Stage all files**

```bash
git add .gitignore README.md .github/workflows/deploy.yml \
  stacks/watchtower/docker-compose.yml stacks/watchtower/.env.example \
  docs/
```

- [ ] **Step 2: Verify staged files look correct (no .env sneaking in)**

```bash
git status
```

Expected: only the files above listed as "new file". No `.env` files.

- [ ] **Step 3: Commit**

```bash
git commit -m "feat: initial repo scaffold with Watchtower stack and GitOps workflow"
```

- [ ] **Step 4: Push**

```bash
git push -u origin main
```

Expected: `Branch 'main' set up to track remote branch 'main' from 'origin'.`

- [ ] **Step 5: Verify repo visible on GitHub**

```bash
gh repo view longieirl/portainer-stacks --hostname github.com
```

Expected: repo description and metadata printed.

---

### Task 7: Generate SSH deploy key and add to GitHub repo

> **Security note:** This key grants read access to the repo. The private key goes on your Portainer server. Keep it safe — do not paste it anywhere else.

- [ ] **Step 1: Generate key pair (no passphrase — Portainer can't prompt)**

```bash
ssh-keygen -t ed25519 -C "portainer-deploy-key" \
  -f ~/.ssh/portainer_deploy_key -N ""
```

Expected: two files created — `~/.ssh/portainer_deploy_key` (private) and `~/.ssh/portainer_deploy_key.pub` (public).

- [ ] **Step 2: Add public key to GitHub repo as deploy key (read-only)**

```bash
gh repo deploy-key add ~/.ssh/portainer_deploy_key.pub \
  --hostname github.com \
  --repo longieirl/portainer-stacks \
  --title "portainer-server" \
  --read-only
```

Expected: `✓ Deploy key added to longieirl/portainer-stacks`

- [ ] **Step 3: Print private key for copying to Portainer server**

```bash
cat ~/.ssh/portainer_deploy_key
```

Copy this output. You will paste it into Portainer's git auth config in Task 9. Do not share or commit this value anywhere.

- [ ] **Step 4: Verify deploy key appears in GitHub**

```bash
gh repo deploy-key list \
  --hostname github.com \
  --repo longieirl/portainer-stacks
```

Expected: `portainer-server` listed with read-only access.

---

### Task 8: Migrate each existing Portainer stack to git

> Repeat this task for every existing stack. Replace `<stack-name>` with the exact name shown in Portainer's Stacks list.

**Files:**
- Create: `stacks/<stack-name>/docker-compose.yml`
- Create: `stacks/<stack-name>/.env.example`

- [ ] **Step 1: In Portainer UI — open the stack and copy its compose content**

Navigate to: Portainer → Stacks → `<stack-name>` → Editor tab.
Select all, copy. This is the current running compose definition.

- [ ] **Step 2: Create the stack directory**

```bash
mkdir -p stacks/<stack-name>
```

- [ ] **Step 3: Paste compose content into docker-compose.yml**

Create `stacks/<stack-name>/docker-compose.yml` with the copied content.

Then audit it:
- Replace any hardcoded secret values with `${VAR_NAME}` references
- Ensure no `env_file:` directives (Portainer GitOps clones to temp dir — no `.env` there)
- Confirm image tags are `repo/image:latest` (or leave pinned tags if you don't want Watchtower to update that service)

- [ ] **Step 4: Create .env.example listing every var the compose references**

Create `stacks/<stack-name>/.env.example`:

```bash
# Required vars for <stack-name>
# Copy this file to understand what to set in Portainer's Environment Variables UI

EXAMPLE_VAR=           # description of what this is
ANOTHER_VAR=           # description
```

- [ ] **Step 5: Commit the stack**

```bash
git add stacks/<stack-name>/
git commit -m "feat: add <stack-name> stack"
```

- [ ] **Step 6: Push (do NOT wire Portainer yet — do all stacks first, wire in Task 9)**

```bash
git push
```

---

### Task 9: Wire each stack in Portainer to GitOps mode

> Perform this for each stack after all compose files are in git. Do Watchtower last.
> **Warning:** Switching a stack from manual to Git mode will redeploy it. Do during low-traffic window.

- [ ] **Step 1: In Portainer UI — open the stack → Settings tab**

- [ ] **Step 2: Change "Build method" to "Git repository"**

Fill in:

| Field | Value |
|---|---|
| Repository URL | `git@github.com:longieirl/portainer-stacks.git` |
| Repository reference | `refs/heads/main` |
| Compose path | `stacks/<stack-name>/docker-compose.yml` |
| Authentication | SSH — paste private key from `~/.ssh/portainer_deploy_key` |
| Auto updates | OFF |

- [ ] **Step 3: Set environment variables in Portainer**

Under "Environment variables" on the same stack config page:
- Add each var from `.env.example` with its real value
- These replace what was previously in the manual compose or server `.env`

- [ ] **Step 4: Click "Save settings" — Portainer will redeploy**

Verify the stack comes back up:
```
Portainer → Stacks → <stack-name> → Containers tab → all containers Running
```

- [ ] **Step 5: Copy the stack's webhook URL**

```
Portainer → Stacks → <stack-name> → Settings tab → Webhook section → copy URL
```

URL format: `https://<portainer-host>/api/stacks/webhooks/<uuid>`

Save this — you need it in Task 10.

---

### Task 10: Add Portainer webhook URLs as GitHub Actions secrets

> One secret per stack. Secret name must match the mapping in `deploy.yml`.
> Naming rule: stack folder name → uppercase, hyphens → underscores, prefix `PORTAINER_WEBHOOK_`.

- [ ] **Step 1: Add secret for each stack**

```bash
gh secret set PORTAINER_WEBHOOK_<STACKNAME> \
  --hostname github.com \
  --repo longieirl/portainer-stacks \
  --body "https://<portainer-host>/api/stacks/webhooks/<uuid>"
```

Example for a stack named `my-app`:
```bash
gh secret set PORTAINER_WEBHOOK_MY_APP \
  --hostname github.com \
  --repo longieirl/portainer-stacks \
  --body "https://portainer.example.com/api/stacks/webhooks/abc123..."
```

- [ ] **Step 2: Add the matching env line to deploy.yml for each new stack**

Open `.github/workflows/deploy.yml` and add to the `env:` block:

```yaml
env:
  PORTAINER_WEBHOOK_WATCHTOWER: ${{ secrets.PORTAINER_WEBHOOK_WATCHTOWER }}
  PORTAINER_WEBHOOK_MY_APP: ${{ secrets.PORTAINER_WEBHOOK_MY_APP }}
  # one line per stack
```

- [ ] **Step 3: Commit and push deploy.yml update**

```bash
git add .github/workflows/deploy.yml
git commit -m "chore: add webhook env mappings for all stacks"
git push
```

- [ ] **Step 4: Verify secrets visible (values hidden)**

```bash
gh secret list \
  --hostname github.com \
  --repo longieirl/portainer-stacks
```

Expected: each `PORTAINER_WEBHOOK_*` secret listed.

---

### Task 11: End-to-end verification

- [ ] **Step 1: Make a trivial change to one stack's compose file**

```bash
# Add a harmless label to any service in stacks/<stack-name>/docker-compose.yml
# Example: under the service's labels section add:
#   - "gitops.test=true"
git add stacks/<stack-name>/docker-compose.yml
git commit -m "chore: gitops end-to-end test"
git push
```

- [ ] **Step 2: Watch the GitHub Actions run**

```bash
gh run watch --hostname github.com --repo longieirl/portainer-stacks
```

Expected: workflow triggers, detects `<stack-name>` as changed, HTTP 200 from Portainer webhook.

- [ ] **Step 3: Verify Portainer redeployed the stack**

In Portainer UI: Stacks → `<stack-name>` → Activity log tab.
Expected: new deployment entry with timestamp matching the push.

- [ ] **Step 4: Verify Watchtower is running**

```bash
# SSH into your server and run:
docker ps --filter name=watchtower
```

Expected: `watchtower` container listed with status `Up`.

- [ ] **Step 5: Remove the test label, commit clean-up**

```bash
git add stacks/<stack-name>/docker-compose.yml
git commit -m "chore: remove gitops test label"
git push
```

---

## Done

At this point:
- All stacks tracked in git
- Push to `main` auto-deploys changed stacks via Portainer webhooks
- Watchtower pulls updated images nightly at 4am
- Secrets never touch the repo — live in Portainer's UI only

**To add a future stack:** follow Task 8 → Task 9 → Task 10 in sequence.
