<div align="center">

# Digital Independence

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-29.4+-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![GitHub Issues](https://img.shields.io/badge/GitHub_Issues-Open-orange?logo=github)](https://github.com/ricalnet/digital-independence/issues)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/ricalnet/digital-independence/graphs/commit-activity)

**Take back control of your digital life, one container at a time.**

</div>

## 📌 Overview

Digital Independence is a collection of ready-to-use Docker Compose configurations for running various self-hosted services on your own infrastructure. This project empowers individuals and small organizations to:

- 📊 Eliminate third-party access and data mining
- 🔒 Keep everything within your infrastructure
- 🔄 Enjoy freedom to switch, modify, or replace services
- 💰 Eliminate recurring subscription fees
- 🎯 Build valuable DevOps and system administration skills

## ✨ Available Services

| Icon | Service Name | Directory Path | Port | License | Brief Description |
|------|--------------|----------------|------|---------|-------------------|
| 🔑 | **Authentik** | `authentik/` | 9000, 9443 | [LICENSE](https://github.com/goauthentik/authentik/blob/main/LICENSE) | Flexible open-source Identity Provider (SSO, LDAP, OAuth2, SAML). |
| 📊 | **Dashdot** | `dashdot/` | 3001 | [LICENSE](https://github.com/MauriceNino/dashdot/blob/main/LICENSE.md) | Lightweight and informative system dashboard. |
| 💬 | **Element Web** | `element-web/` | 8009 | [LICENSE](https://github.com/element-hq/element-web/blob/develop/LICENSE-AGPL-3.0) | Modern web client for the Matrix communication protocol. |
| 🗂️ | **Homarr** | `homarr/` | 7575 | [LICENSE](https://github.com/homarr-labs/homarr/blob/dev/LICENSE) | Modular dashboard to manage all your services. |
| 🖼️ | **Immich** | `immich-app/` | 2283 | [LICENSE](https://github.com/immich-app/immich/blob/main/LICENSE) | Self-hosted photo and video management solution (Google Photos alternative). |
| 🎥 | **Jellyfin** | `jellyfin/` | 8096, 8920 | [LICENSE](https://github.com/jellyfin/jellyfin/blob/master/LICENSE) | Open-source media server for streaming movies, music, and TV. |
| 🌐 | **LibreTranslate** | `libretranslate/` | 5001 | [LICENSE](https://github.com/LibreTranslate/LibreTranslate/blob/main/LICENSE) | Offline translation engine that respects privacy. |
| 🔗 | **LinkStack** | `linkstack/` | 8003 | [LICENSE](https://github.com/LinkStackOrg/LinkStack/blob/main/LICENSE) | Self-hosted open-source link sharing platform (Linktree alternative). |
| 🐘 | **Mastodon** | `mastodon/` | 4000, 4001 | [LICENSE](https://github.com/mastodon/mastodon/blob/main/LICENSE) | Federated social networking server (Twitter/X alternative). |
| 🎵 | **Navidrome** | `navidrome/` | 4533 | [LICENSE](https://github.com/navidrome/navidrome/blob/master/LICENSE) | Modern music streaming server with Subsonic support. |
| ☁️ | **Nextcloud** | `nextcloud/` | 5000 | [LICENSE](https://github.com/nextcloud/server/tree/master/LICENSES) | Complete cloud storage and collaboration platform. |
| 🔔 | **ntfy** | `ntfy/` | 8010 | [LICENSE](https://github.com/binwiederhier/ntfy/blob/main/LICENSE) | Simple push notifications via HTTP, ideal for script integration. |
| 🤖 | **Open WebUI + Ollama** | `open-webui/` | 3000, 11434 | [Open WebUI](https://github.com/open-webui/open-webui/blob/main/LICENSE), [Ollama](https://github.com/ollama/ollama/blob/main/LICENSE) | Intuitive LLM interface, supports Ollama and OpenAI API. |
| 🛡️ | **Pi-hole** | `pi-hole/` | 53, 8080 | [LICENSE](https://github.com/pi-hole/pi-hole/blob/master/LICENSE) | DNS-level ad and tracker filtering for your entire network. |
| 🐳 | **Portainer** | `portainer/` | 9443 | [LICENSE](https://github.com/portainer/portainer/blob/develop/LICENSE) | Docker container management via web interface. |
| 🔍 | **SearXNG** | `searxng/` | 8888 | [LICENSE](https://github.com/searxng/searxng/blob/master/LICENSE) | Privacy-respecting metasearch engine. |
| 📨 | **Synapse** | `synapse/` | 8008, 8448 | [LICENSE](https://github.com/element-hq/synapse/blob/develop/LICENSE-AGPL-3.0) | Reference server for the Matrix communication network. |
| ⏱️ | **Uptime Kuma** | `uptime-kuma/` | 9442 | [LICENSE](https://github.com/louislam/uptime-kuma/blob/master/LICENSE) | Service status monitoring with real-time notifications. |
| 🔐 | **Vaultwarden** | `vaultwarden/` | 8000 | [LICENSE](https://github.com/dani-garcia/vaultwarden/blob/main/LICENSE.txt) | Bitwarden-compatible password management server, lightweight version. |
| 📚 | **MediaWiki** | `wiki/` | 8002 | [LICENSE](https://github.com/wikimedia/mediawiki?tab=License-1-ov-file) | Wiki platform used by Wikipedia. |
| 🔗 | **YOURLS** | `yourls/` | 8001 | [LICENSE](https://github.com/YOURLS/YOURLS/blob/master/LICENSE) | Self-hosted URL shortening service. |

> Ports listed are the default ports on the host. Some services are only bound to `127.0.0.1` (localhost) for security reasons. Modify the configuration in each service's `docker-compose.yml` to bind to `0.0.0.0` or change the port.

### Additional Synapse Services (Bridges)

- `synapse:mautrix-telegram` – Telegram bridge
- `synapse:mautrix-whatsapp` – WhatsApp bridge

## 📋 Prerequisites

Before starting, ensure your system meets the following requirements:

| Requirement | Minimum Version | Notes |
|-------------|----------------|-------|
| Docker Engine | 29.4+ | Required for all container operations |
| Docker Compose | v2.0+ | Included with Docker Engine 29.4+ |
| Git | Latest | For cloning the repository |
| Operating System | Linux / macOS / WSL2 | Windows WSL2 recommended |

### Optional Dependencies

- `whiptail` or `dialog` – For interactive menu
- `curl` / `wget` – For downloading dependencies

## 🚀 Getting Started

### 1. Clone the Repository

```bash
cd ~/
git clone https://github.com/ricalnet/digital-independence.git
cd digital-independence
```

### 2. Install Docker Engine

If Docker is not already installed, use the provided installation scripts:

For Debian:
```bash
./install-docker-engine-on-debian.sh
```

For Ubuntu:
```bash
./install-docker-engine-on-ubuntu.sh
```

### 3. Prepare Environment Files

Some services require `.env` configuration files:

```bash
# Example for Immich
cp immich-app/.env.example immich-app/.env
nano immich-app/.env   # adjust as needed
```

### 4. Manage Services

Use the `sovereign.sh` script to start, stop, and manage all services (see next section).

## ⚙️ Using `sovereign.sh`

`sovereign.sh` is a powerful command-line tool designed to simplify management of all services in one command.

### Interactive Menu (Easiest for Beginners)

```bash
./sovereign.sh -i
```

Or simply run without arguments:

```bash
./sovereign.sh
```

### Quick Command Examples

| Purpose | Command |
|---------|---------|
| Start a single service | `./sovereign.sh portainer` |
| Start all services | `./sovereign.sh -a up` |
| Stop a service | `./sovereign.sh -d portainer` |
| Restart services | `./sovereign.sh -r portainer vaultwarden` |
| Update images and restart | `./sovereign.sh recycle synapse` |
| Update without downtime | `./sovereign.sh update immich` |
| Simulate commands (dry-run) | `./sovereign.sh -n up portainer` |
| View service logs | `./sovereign.sh logs portainer` |
| Check service status | `./sovereign.sh ps` |

> For Synapse sub-services, use `synapse:mautrix-telegram` or `synapse:mautrix-whatsapp`.

### Full Help Guide

```bash
./sovereign.sh -h
```

<details>
<summary>📘 Click to expand full help guide</summary>

```bash
Digital Independence by Ricalnet
SOVEREIGN.SH v2.0.0

USAGE:
    ./sovereign.sh [OPTIONS] [ACTION] [SERVICE...]

OPTIONS:
    -h, --help              Show this help message
    -l, --list              List all available services
    -a, --all               Run action on all services
    -d, --down              Stop and remove containers (ACTION)
    -r, --restart           Restart services (ACTION)
    -p, --pull              Pull latest images before action
    -b, --build             Build images before action
    -v, --verbose           Show detailed output
    -i, --interactive       Interactive checkbox menu
    -n, --dry-run           Show what would be executed (no changes)
    -s, --sudo              Use sudo for docker commands
    --no-color              Disable colored output

ACTIONS:
    up                      Start services (default)
    down                    Stop and remove services
    restart                 Restart services
    logs                    Show logs (last 50 lines)
    ps                      Show container status
    prune                   Clean up unused resources

COMBINED ACTIONS:
    recycle                 PULL → DOWN → UP (full refresh with new images)
    update                  PULL → UP (update without downtime)
    fresh                   DOWN → UP (recreate without pull)

EXAMPLES:
    ./sovereign.sh portainer                                    # Start portainer
    ./sovereign.sh -a up                                        # Start all services
    ./sovereign.sh -d portainer                                 # Stop portainer
    ./sovereign.sh -r portainer vaultwarden                     # Restart services
    ./sovereign.sh --pull --all up                              # Update all services
    ./sovereign.sh recycle synapse                              # Full refresh synapse
    ./sovereign.sh recycle synapse synapse:mautrix-telegram     # Refresh synapse + bridges
    ./sovereign.sh fresh immich                                 # Recreate immich only
    ./sovereign.sh -n up portainer                              # Dry run
    ./sovereign.sh -i                                           # Interactive mode

SERVICE NAMING:
    • Main services: use service name directly
    • Synapse sub-services: synapse:mautrix-telegram, synapse:mautrix-whatsapp

RECYCLE SEQUENCE:
    1. PULL  → Download latest images (container still running)
    2. DOWN  → Stop and remove old container
    3. UP    → Start new container with fresh image and config
```
</details>

## 🌐 Exposing Services to the Internet

By default, services are only accessible from localhost. To access them securely from the internet, this repository supports two approaches:

### 🧅 Tor Hidden Service (.onion)

Anonymous access through the Tor network, ideal for maximum privacy.

- 📖 [Tor Hidden Service Implementation Guide](https://docs.ricalnet.my.id/posts/panduan-implementasi-hidden-service-tor/)
- Benefits: No need for domain names, true anonymity, resistant to censorship

### ☁️ Cloudflare Tunnel

Access through Cloudflare without opening firewall ports.

- 📖 [Cloudflare Tunnel Configuration Guide](https://docs.ricalnet.my.id/posts/panduan-lengkap-mengonfigurasi-cloudflare-tunnel-untuk-ekspos-layanan-lokal/)
- Benefits: DDoS protection, built-in SSL, no public IP required

## 🔐 Security & Maintenance Guidelines

To keep your system secure and stable, follow these recommendations:

### Initial Setup

- 🔑 Change all default passwords immediately in `.env` files
- 🔒 Use strong, unique secrets for each service
- 🌐 Bind to localhost (127.0.0.1) unless you need external access
- 📁 Set proper file permissions: `chmod 600 .env` for sensitive files

### Ongoing Maintenance

- 📦 Container data is stored in local directories or Docker volumes
- ⬆️ Use `--pull` option to get security patches and updates
- 📰 Read upstream changelogs before major version upgrades
- 🔍 Monitor logs for suspicious activity: `./sovereign.sh logs [service]`
- 📊 Enable health checks and monitoring with Uptime Kuma

## 💾 Backup & Recovery

Protect your data with a robust backup solution using [Chantik](https://github.com/ricalnet/chantik) – a ChaCha20-Authenticated Backup Protection tool designed specifically for Docker environments.

## 🤖 Automation Scripts

This repository includes automation scripts for scheduled maintenance. The scripts are located in `automation-scripts/` and can be configured via cron jobs.

### 📅 Weekly Updates

Automatically pulls latest images and updates services without downtime.

```bash
# Copy and configure the config file
cp automation-scripts/weekly-updates/weekly_updates.conf.example automation-scripts/weekly-updates/weekly_updates.conf
nano automation-scripts/weekly-updates/weekly_updates.conf
```

### 🔄 Monthly Recycle

Performs a full refresh (pull → down → up) on selected services to ensure fresh containers.

```bash
# Copy and configure the config file
cp automation-scripts/monthly-recycle/monthly_recycle.conf.example automation-scripts/monthly-recycle/monthly_recycle.conf
nano automation-scripts/monthly-recycle/monthly_recycle.conf
```

### ⏰ Setting Up Cron Jobs

Add these entries to your crontab for automated maintenance:

```bash
sudo crontab -e
```

```bash
# Weekly updates - every Sunday at 3 AM
0 3 * * 0 /path/to/digital-independence/automation-scripts/weekly-updates/weekly_updates.sh

# Monthly recycle - every 1st day of the month at 6 AM
0 6 1 * * /path/to/digital-independence/automation-scripts/monthly-recycle/monthly_recycle.sh
```

> Replace `/path/to/digital-independence/` with the actual path where you cloned the repository.

### Script Configuration

| Script | Config File | Purpose |
|--------|-------------|---------|
| `weekly_updates.sh` | `weekly_updates.conf` | List of services to update weekly |
| `monthly_recycle.sh` | `monthly_recycle.conf` | List of services to recycle monthly |

The scripts automatically log their output to `logs/` directory for monitoring and troubleshooting.

## 🤝 Contributing

Here are some areas where you can help:

- Adding configurations for new services
- Fixing bugs or improving features in `sovereign.sh`
- Completing or improving documentation

Please open an [Issue](https://github.com/ricalnet/digital-independence/issues) or submit a [Pull Request](https://github.com/ricalnet/digital-independence/pulls).

## 📜 License

This repository uses the [MIT License](LICENSE). However, each included service has its own license. Please comply with the license terms of each upstream project.