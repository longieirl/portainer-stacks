# Security Policy

## Scope

This repository contains Docker Compose configuration files for self-hosted services
running on a private home network. It does not contain application code or handle
public user data.

## Reporting a vulnerability

If you find a security issue in this repository — for example, a committed secret,
an insecure default in a compose file, or a workflow that could be exploited — please
report it privately rather than opening a public GitHub issue.

**Report via:** [GitHub Security Advisory](https://github.com/longieirl/portainer-stacks/security/advisories/new)
via the Security tab of this repository.

Include:
- What you found
- Which file or configuration is affected
- Why it is a risk
- A suggested fix if you have one

You will receive a response within 5 business days. There is no bug bounty program.

## Supported versions

Only the `main` branch is actively maintained.

## Push protection bypass policy

Secret scanning push protection can be bypassed by users with write access. This is not
permitted unless the detected secret is a confirmed false positive. Any bypass must be
reviewed by the repository owner. Bypass events are logged in the repository audit log.

## Known accepted risks

The following patterns exist intentionally and are documented here:

| Pattern | File | Reason |
|---|---|---|
| `/var/run/docker.sock` mount | `stacks/watchtower/docker-compose.yml` | Watchtower requires Docker socket to manage containers |
| `cap_add: NET_ADMIN` | `stacks/gluetun/docker-compose.yml` | Required for WireGuard VPN tunnel |
| `/dev/net/tun` device | `stacks/gluetun/docker-compose.yml` | Required for WireGuard VPN tunnel |
| `:latest` image tags | all stacks | Intentional — Watchtower manages updates |
