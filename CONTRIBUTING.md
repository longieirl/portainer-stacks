# Contributing

Thanks for improving this repo. Read this before opening a PR.

## What this repo is

GitOps-managed Docker Compose stacks for a private Portainer CE instance. Changes here
are automatically deployed to a home server via Portainer's polling mechanism.

## How to contribute

### Fork-based flow

1. Fork this repository.
2. Create a branch from `main`: `git checkout -b type/short-description`
   Branch types: `feat` | `fix` | `perf` | `chore` | `docs` | `refactor`
3. Make your change. One logical change per PR.
4. Validate locally before pushing (see below).
5. Open a PR against `main` in this repo.
6. Fill in the PR template completely.

Direct pushes to `main` are blocked. All changes require a PR and owner review.

### Validate before pushing

For any stack you touched:

```bash
docker compose -f stacks/<stack-name>/docker-compose.yml config
```

This command must exit 0 with no errors. If Docker is not available locally, the CI
check will catch it — but fixing it locally is faster.

### One logical change per PR

- One new stack = one PR.
- One bug fix = one PR.
- Do not mix unrelated stacks in a single PR.

## What is and is not allowed

### Never commit

- `.env` files with real values (`stack.env`, `.env`, etc.)
- Secrets, credentials, API keys, tokens, passwords
- Private IP addresses from your own network
- Personal paths (e.g. `/Users/yourname/...`) — use `${DOCKER_DATA_HOME}` and `${DOCKER_SHARED_HOME}`
- Pinned image tags unless you document the reason in a comment

### YAML conventions

- Stack folder name must exactly match the Portainer stack name.
- Compose file lives at `stacks/<stack-name>/docker-compose.yml`.
- Document required environment variables in `stacks/<stack-name>/.env.example`.
- `image:` tags use `:latest` — Watchtower handles updates.
- Indent with 2 spaces. No tabs.

### Security-sensitive patterns

The following are flagged by CI for owner review — they are not automatically blocked,
but they require a clear justification in the PR description:

- `privileged: true`
- `network_mode: host`
- `/var/run/docker.sock` volume mounts
- `cap_add` entries other than `NET_ADMIN` (which gluetun requires)
- Ports bound to `0.0.0.0` (all interfaces)
- `user: root` or missing `user:` on containers that don't need root

## Code review

The repo owner (`@longieirl`) reviews all PRs. Expect feedback within a few days.
Reviews focus on security, correctness, and consistency with existing stacks.
