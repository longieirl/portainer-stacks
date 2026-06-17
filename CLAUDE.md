# CLAUDE.md

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
- If mid-task you discover the goal was wrong (e.g. the real issue is elsewhere), stop. Restate the correct goal and confirm before continuing — don't finish the wrong task just because you started it.
- Prefer type guards over `as SomeType` casts. If a cast is unavoidable after a runtime check, add a comment explaining why.

---

## 2. Simplicity First

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked
- No abstractions for single-use code
- No "flexibility" or "configurability" that wasn't requested
- No error handling for impossible scenarios
- If you write 200 lines and it could be 50, rewrite it

Ask: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

---

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting
- Don't refactor things that aren't broken
- Match existing style, even if you'd do it differently
- If you notice unrelated dead code, mention it — don't delete it
- If a snapshot fails after your change, update only the affected snapshots — never bulk-update with `--updateSnapshot` as it silently hides regressions

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused
- Don't remove pre-existing dead code unless asked

The test: Every changed line should trace directly to the user's request.

---

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

---

## 5. Git Conventions

Commit format: `type: description`

Types: `feat` | `fix` | `perf` | `chore` | `docs` | `refactor` | `test`

Branch naming: `type/short-description` (e.g. `fix/gluetun-subnet`, `feat/new-stack`)

If working on a GitHub issue, include the issue ID: `type/123-short-description`

PRs require:
- 1 approving review
- Security scan pass (no secrets, no flagged vulnerabilities)
- All tests passing locally before push

Never push directly to `main`. Always work on a branch.

---

## 6. Safety Rules

- Flag security issues before any other recommendation
- Never commit secrets, credentials, or private keys
- Before making any change, verify it will work — check current docs if uncertain
- Never modify production stacks without explicit instruction

---

## Project

**portainer-stacks** — GitOps-managed Docker Compose stacks for a Portainer CE instance running on macOS.

## Stack

- Portainer CE (Community Edition) on macOS
- Docker Compose (no Swarm, no Kubernetes)
- GitHub Actions for webhook-based deploys
- Watchtower for nightly image auto-updates

## Key URLs

- Repo: https://github.com/longieirl/portainer-stacks
- Portainer: https://localhost:9443

## Domain Rules

- Stack folder name must exactly match the Portainer stack name
- `image:` tags use `:latest` — Watchtower handles updates, no pinning
- No secrets in git — real values set in Portainer's Environment Variables UI per stack
- `.env.example` per stack documents all required vars
- `DOCKER_DATA_HOME` and `DOCKER_SHARED_HOME` must be set in Portainer UI for every stack (CE has no global env var injection)
- `stack.env` files must not be committed — they would expose host paths when repo goes public
- Portainer is started manually via `docker run` (see README) — it is not a managed stack
- Never use `privileged: true` unless strictly required and documented why
- gluetun must be running before deluge, jackett, and qbittorrent (all use `network_mode: container:gluetun`)

## Secrets reference

| Stack | Secret vars (Portainer UI only) |
|---|---|
| gluetun | `WIREGUARD_PRIVATE_KEY` |
| n8n | `POSTGRES_PASSWORD`, `N8N_ENCRYPTION_KEY` |
