## Summary

<!-- What does this PR change and why? -->

## Stack affected

<!-- Which stack(s) does this change touch? (e.g. gluetun, n8n, watchtower, all) -->

## Security impact

<!-- Does this change affect secrets, network exposure, volumes, capabilities, or image versions? -->
<!-- If none, write "None". -->

## Test evidence

<!-- Paste the output of `docker compose -f stacks/<stack>/docker-compose.yml config`
     showing the compose file is valid, or describe how you verified the change. -->

```bash
docker compose -f stacks/<stack>/docker-compose.yml config
```

## Checklist

- [ ] No secrets, credentials, tokens, passwords, or private IPs committed
- [ ] No real `stack.env` or `.env` files committed (only `.env.example` allowed)
- [ ] `docker compose config` passes for every changed stack
- [ ] Image tags use `:latest` (do not pin unless there is a documented reason)
- [ ] `DOCKER_DATA_HOME` and `DOCKER_SHARED_HOME` are referenced via env var, not hardcoded paths
