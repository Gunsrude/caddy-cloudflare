# Caddy + Cloudflare DNS-01 (Docker)

A custom Caddy Docker image compiled with the [Cloudflare DNS-01](https://github.com/caddy-dns/cloudflare) module for automatic TLS certificate provisioning via ACME DNS challenges.

## What it does

This image runs Caddy as a reverse proxy in front of your other Docker containers, handling HTTPS automatically using Cloudflare's DNS API to complete ACME DNS-01 challenges.

## Quick start

1. **Clone and configure**

   ```bash
   git clone <repo-url>
   cd caddy-cloudflare
   cp .env.example .env
   # Edit .env and add your Cloudflare API token
   ```

2. **Customize the Caddyfile**

    Edit `conf/Caddyfile` to match your domain(s) and upstream services. Each block should point to a container name on your Docker network (e.g., `web:80`, `grafana:3000`).

3. **Start with docker-compose**

   ```bash
   cp docker-compose.yml.example docker-compose.yml
   docker compose up -d
   ```

4. **Verify**

   Caddy will request a TLS certificate from Let's Encrypt using your Cloudflare DNS token. Check the logs:

   ```bash
   docker compose logs -f caddy
   ```

## Cloudflare token setup

You need a Cloudflare API Token with **Zone.DNS** permission for the zone(s) you're proxying. Generate one at https://dash.cloudflare.com/profile/api-tokens with a custom token using the "Edit zone DNS" template.

The token goes in your `.env` file:

```
CLOUDFLARE_API_TOKEN=<your-token-here>
```

Both `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_DNS_API_TOKEN` are supported — use whichever you prefer.

## Customizing the Caddyfile

The mounted `conf/Caddyfile` is the main configuration point. Each site block maps to a domain and proxies to an upstream service:

```
myapp.example.com {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    reverse_proxy myapp-service:3000
}
```

Changes take effect after reloading Caddy:

```bash
docker compose restart caddy
```

## Docker network note

Upstream services (the targets of `reverse_proxy`) must be on the same Docker network as Caddy so they can be resolved by container name. The example compose file assumes this — adjust if you're using custom networks.

## Directory structure

This project follows official Caddy Docker conventions:

```
caddy-cloudflare/
├── conf/                  # Configuration directory (mounted at /etc/caddy)
│   └── Caddyfile         # Your Caddy configuration
├── docker-compose.yml     # Or use docker-compose.yml.example as template
├── Dockerfile            # Custom Caddy build with Cloudflare module
└── .env                  # Environment variables (CLOUDFLARE_API_TOKEN)
```

**Volume mounts:**
- `./conf:/etc/caddy` - Configuration files (folder mount)
- `caddy_data:/data` - TLS certificates, keys, OCSP staples (MUST persist)
- `caddy_config:/config` - autosave.json and runtime config (optional to persist)

We mount the entire `conf/` folder instead of a single file so Caddy can access any additional configuration files you might add (like templates or includes), matching the official Caddy image convention.
