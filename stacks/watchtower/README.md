# Watchtower

Automatic container image updater. Runs nightly at 04:00 and pulls updated images for containers labelled `com.centurylinklabs.watchtower.enable=true`. Removes old images after update.

No web UI. No exposed ports.

## Architecture

Watchtower reads the Docker socket (`/var/run/docker.sock:ro`) to discover and update running containers. Only containers with the opt-in label are updated — all stacks in this repo set the label explicitly (`true` to update, `false` to pin).

## Schedule

Runs daily at **04:00** (cron: `0 0 4 * * *`).

## Required environment variables

Set in Portainer UI → stack → Environment variables:

| Variable | Default | Notes |
|---|---|---|
| `WATCHTOWER_NOTIFICATIONS` | *(empty)* | Notification type, e.g. `slack` |
| `WATCHTOWER_NOTIFICATION_URL` | *(empty)* | Shoutrrr notification URL |

Both are optional. Leave empty to disable notifications.

## Verify after deploy

**1. Container running:**
```bash
docker ps | grep watchtower
```

**2. Check logs for last run:**
```bash
docker logs watchtower
```

Expected output includes `Checked X containers, updated Y` after the scheduled run.
