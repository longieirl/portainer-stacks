# Architecture

```mermaid
graph TB
    subgraph INTERNET["☁️ Internet"]
        CF["Cloudflare\nDNS + Access"]
    end

    subgraph HOST["🖥️ macOS Host — 192.168.1.6 (Tailscale: 100.103.88.27)"]
        subgraph REMOTE_ACCESS["remote-access network"]
            CADDY["Caddy\nreverse proxy + TLS\nports 80/443"]
            N8N["n8n :5678"]
        end

        subgraph N8N_NET["n8n_net (internal)"]
            PG["postgres:16"]
        end

        subgraph PROXY_NET["proxy_net (bridge)"]
            SONARR["Sonarr :8989"]
            TAUTULLI["Tautulli :8181"]
            OVERSEERR["Overseerr :5055"]
        end

        subgraph VPN_NET["gluetun — Surfshark WireGuard VPN\n(network_mode: container:gluetun)"]
            GLUETUN["gluetun"]
            QB["qBittorrent :8080"]
            DELUGE["Deluge :8112\nLAN direct only"]
            JACKETT["Jackett :9117\nLAN direct only"]
            FLARE["FlareSolverr :8191"]
        end

        PLEX["Plex Media Server\n(native, non-Docker) :32400"]
        PORTAINER["Portainer CE :9443"]
        WATCHTOWER["Watchtower\nnightly 04:00"]
    end

    subgraph CF_TUNNEL["Cloudflare Tunnel (in caddy stack)"]
        CLOUDFLARED["cloudflared sidecar"]
    end

    %% Internet → n8n via Cloudflare Tunnel
    CF -- "n8n.longie.net\n(Cloudflare Access enforced)" --> CLOUDFLARED
    CLOUDFLARED --> N8N

    %% Tailscale/LAN via Caddy
    CF -. "DNS only" .-> CADDY
    CADDY -- "portainer.longie.net" --> PORTAINER
    CADDY -- "sonarr.longie.net" --> SONARR
    CADDY -- "qbt.longie.net" --> QB
    CADDY -- "n8n.longie.net (LAN)" --> N8N
    CADDY -- "tautulli.longie.net" --> TAUTULLI
    CADDY -- "overseerr.longie.net" --> OVERSEERR

    %% n8n ↔ DB
    N8N --- PG

    %% VPN grouping
    GLUETUN -. "VPN tunnel" .-> QB
    GLUETUN -. "VPN tunnel" .-> DELUGE
    GLUETUN -. "VPN tunnel" .-> JACKETT
    GLUETUN -. "VPN tunnel" .-> FLARE

    %% Plex monitoring
    TAUTULLI -. "host.docker.internal:32400" .-> PLEX
    OVERSEERR -. "host.docker.internal:32400" .-> PLEX
```

## Access summary

| Service | URL | Access path |
|---|---|---|
| n8n | `https://n8n.longie.net` | Internet — Cloudflare Tunnel + Access |
| Portainer | `https://portainer.longie.net` | LAN/Tailscale — Caddy reverse proxy |
| Sonarr | `https://sonarr.longie.net` | LAN/Tailscale — Caddy reverse proxy |
| qBittorrent | `https://qbt.longie.net` | LAN/Tailscale — Caddy reverse proxy |
| Tautulli | `https://tautulli.longie.net` | LAN/Tailscale — Caddy reverse proxy |
| Overseerr | `https://overseerr.longie.net` | LAN/Tailscale — Caddy reverse proxy |
| Jackett | `http://192.168.1.6:9117` | LAN direct — no Caddy |
| Deluge | `http://192.168.1.6:8112` | LAN direct — no Caddy |
