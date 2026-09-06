<div align="center">

# Digital Independence

**Take back control of your digital life, one container at a time.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Podman](https://img.shields.io/badge/Podman-5+-2496ED?logo=podman&logoColor=white)](https://podman.io/)
[![Rootless](https://img.shields.io/badge/Rootless-✅_Supported-8A2BE2?logo=podman&logoColor=white)](https://podman.io/docs/rootless)
[![Architecture](https://img.shields.io/badge/Architecture-amd64_|_arm64-4EAA25?logo=linux&logoColor=white)](https://hub.docker.com/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/ricalnet/digital-independence/graphs/commit-activity)
[![Backup](https://img.shields.io/badge/Backup-ChaCha20--Poly1305-8A2BE2?logo=openssl&logoColor=white)](https://github.com/ricalnet/digital-independence#-chantik-encrypted-backup--restore)

</div>

## 📌 What is Digital Independence?

Digital Independence is a complete self-hosting solution that provides `podman-compose` configurations for 23+ popular open-source services. It eliminates dependency on third-party cloud services by giving you full control over your data and infrastructure.

Core Philosophy:
- 🔒 Total Data Ownership — Your data stays on your hardware, always
- 💰 Zero Recurring Costs — Pay once for hardware, free forever
- 🔄 Complete Freedom — Switch, modify, or replace any service anytime
- 🎯 Practical Learning — Build real DevOps skills through hands-on experience
- 🚀 Ready to Deploy — Just clone, install, and run

## 🏗️ Architecture Support

| Architecture | Platforms | Status |
|--------------|-----------|--------|
| `linux/amd64` | Intel/AMD, x86_64 | ✅ Supported |
| `linux/arm64` | Raspberry Pi 4/5, Apple M1/M2/M3, AWS Graviton | ✅ Supported |

## 📦 Available Services (23 Services)

### 🔐 Security & Authentication

| Service | Directory | Port | Purpose |
|---------|-----------|------|---------|
| Wazuh | `wazuh/` | 443 | Security monitoring and threat detection |
| Pi-hole | `pi-hole/` | 53, 8080 | Network-wide ad blocking and DNS filtering |
| Vaultwarden | `vaultwarden/` | 8000 | Lightweight Bitwarden-compatible password manager |
| Authentik | `authentik/` | 9000, 9443 | Complete identity and access management (SSO) |

### 🤖 AI & Machine Learning

| Service | Directory | Port | Purpose |
|---------|-----------|------|---------|
| Open WebUI | `open-webui/` | 3000 | Chat interface for Ollama LLMs |

> Configure with `OLLAMA_BASE_URL` in `.env`

### 🖥️ Management & Monitoring

| Service | Directory | Port | Purpose |
|---------|-----------|------|---------|
| Dashdot | `dashdot/` | 3001 | Modern server dashboard with system metrics |
| Homarr | `homarr/` | 7575 | Clean and customizable home page dashboard |
| ntfy | `ntfy/` | 8010 | Simple pub/sub notification service |
| Uptime Kuma | `uptime-kuma/` | 9442 | Self-hosted uptime monitoring |
| Portainer | `portainer/` | 9444 | Container management UI for Podman/Docker |

### 💬 Communication (Matrix Ecosystem)

| Service | Directory | Port | Purpose |
|---------|-----------|------|---------|
| Synapse | `synapse/` | 8008, 8448 | Matrix homeserver for decentralized chat |
| Element Web | `element-web/` | 8009 | Web client for Matrix |
| Mautrix Bridges | `synapse/mautrix/` | - | Telegram & WhatsApp bridges (single compose.yaml) |

### 🌐 Search & Translation

| Service | Directory | Port | Purpose |
|---------|-----------|------|---------|
| LibreTranslate | `libretranslate/` | 5001 | Open-source machine translation |
| SearXNG | `searxng/` | 8888 | Privacy-respecting metasearch engine |

### 📁 Media & Content Management

| Service | Directory | Port | Purpose |
|---------|-----------|------|---------|
| Immich | `immich/` | 2283 | Google Photos alternative (self-hosted) |
| Navidrome | `navidrome/` | 4533 | Music streaming server (Subsonic-compatible) |
| Nextcloud | `nextcloud/` | 5000 | Complete productivity suite (files, calendar, contacts) |
| Jellyfin | `jellyfin/` | 8096, 8920 | Full-featured media server (Plex alternative) |

### 🔗 Link Management

| Service | Directory | Port | Purpose |
|---------|-----------|------|---------|
| YOURLS | `yourls/` | 8001 | URL shortener with analytics |
| LinkStack | `linkstack/` | 8003 | Link-sharing and bookmark manager |

### 📚 Knowledge Management

| Service | Directory | Port | Purpose |
|---------|-----------|------|---------|
| MediaWiki | `wiki/` | 8002 | Wikipedia-style wiki engine |

### 🐘 Social Media

| Service | Directory | Port | Purpose |
|---------|-----------|------|---------|
| Mastodon | `mastodon/` | 4000, 4001 | Federated social network (Twitter alternative) |

> Mastodon requires both `.env` (Podman) and `.env.production` (Mastodon configuration)

Important Notes:
- 📖 Full setup guides available in [`docs/`](docs/) directory
- 🔧 Use `dipen env <service>` to automatically create and edit `.env` files
- 🏷️ Services use `latest` tag by default — pin versions for stability if needed
- 🌐 Services bind to `127.0.0.1` (localhost) by default for security

## 📋 Prerequisites

| Requirement | Minimum Version | Notes |
|-------------|-----------------|-------|
| Podman | 5.4+ | Rootless container engine |
| podman-compose | v1.3+ | Compose orchestration for Podman |
| Git | Latest | Version control |
| OS | Linux / macOS / WSL2 | Any POSIX-compatible system |
| Memory | 4GB+ | Depends on services running |
| Storage | 50GB+ | Based on services and data volume |

## 🚀 Quick Start (3 Steps)

### Step 1: Clone Repository
```bash
git clone https://github.com/ricalnet/digital-independence.git
cd digital-independence
```

### Step 2: Install Everything
```bash
./install-podman-on-debian.sh
```

What the installer does:
- Updates and upgrades system
- Installs Podman and podman-compose
- Installs supporting packages (uidmap, slirp4netns, dbus-user-session, fuse-overlayfs)
- Enables linger for user (allows services to run after logout)
- Configures container registries (Docker Hub, GitHub Container Registry, Matrix)
- Enables podman.socket for API access
- Creates `dipen` alias (service orchestration)
- Creates `chantik` alias (backup tool)

### Step 3: Start Services
```bash
# List available services
dipen list

# Configure environment (auto-creates .env from .env.example)
dipen env nextcloud

# Start your service
dipen up nextcloud

# Start all services
dipen all up
```

## ⚙️ dipen: Service Orchestration

`dipen` is the central command-line tool for managing all services.

### Usage Examples

```bash
# Wildcard matching
dipen env n*              # Edit all services starting with 'n'
dipen up n*               # Start all services starting with 'n'

# Multiple services
dipen env nextcloud immich authentik

# Custom editor
EDITOR=vim dipen env immich

# All services
dipen all up              # Start everything
dipen all down            # Stop everything
```

<details>
<summary>📘 Complete dipen Help</summary>

```
dipen v1.1 - Podman Orchestration Tool for Digital Independence
Issues: https://github.com/ricalnet/digital-independence/issues 

USAGE:
    dipen [ACTION] [SERVICE...] [OPTIONS]

ACTIONS:
    env                 Edit .env file (create from .env.example if missing)
    up                  Start services
    down                Stop services
    restart             Restart services
    pull                Pull latest images
    logs                Show logs (last 50 lines)
    ps                  Show status
    prune               Clean unused resources
    recycle             Pull → Down → Up
    update              Pull → Up
    fresh               Down → Up

OPTIONS:
    help                Show this help
    version             Show version
    list                List services
    all                 Run on all services
    dry-run             Show what would be executed

EXAMPLES:
    dipen list
    dipen env nextcloud immich
    dipen env n*
    dipen up nextcloud
    dipen down nextcloud
    dipen restart nextcloud
    dipen pull nextcloud
    dipen logs nextcloud
    dipen ps nextcloud
    dipen prune nextcloud
    dipen update nextcloud
    dipen fresh nextcloud
    dipen recycle nextcloud
    dipen all up
    dipen dry-run up nextcloud
    dipen up n*
```
</details>


## 🌐 Exposing Services Externally

### 🧅 Tor Hidden Service
Provide anonymous access through the Tor network.
- 📖 [Tor Implementation Guide](https://docs.ricalnet.my.id/posts/panduan-implementasi-hidden-service-tor/)

### ☁️ Cloudflare Tunnel
Access services without opening firewall ports.
- 📖 [Cloudflare Tunnel Guide](https://docs.ricalnet.my.id/posts/panduan-lengkap-mengonfigurasi-cloudflare-tunnel-untuk-ekspos-layanan-lokal/)

## 💾 Chantik: Encrypted Backup & Restore

Chantik is a ChaCha20-Authenticated Backup Protection tool included in the repository.

### Key Features

| Feature | Description |
|---------|-------------|
| 🔐 ChaCha20-Poly1305 | Military-grade encryption via OpenSSL |
| 📦 Podman Volume Backup | Backup specific volumes or all |
| 📁 Custom Directory Backup | Backup any directory on your system |
| ⚡ Incremental Backup | Space-efficient with hardlink support |
| 🔄 Auto Rotation | Keep only N latest backups (default: 7) |
| 🔔 NTFY Notifications | Get real-time backup status updates |
| 🔒 Lock Protection | Prevent concurrent backups |

### Quick Setup

```bash
# Copy example configuration
cp chantik.example.conf chantik.conf

# Edit configuration
nano chantik.conf
```

### Usage Examples

```bash
# Basic backup
chantik backup

# Backup with specific config
chantik -c /etc/chantik/chantik.conf backup

# Restore latest backup
chantik restore

# Restore specific service
chantik restore -s nextcloud

# Restore specific backup file
chantik restore -b /backup/chantik-20260109-120000.tar.gz.enc

# List all backups
chantik list

# Verify last backup
chantik verify

# Clean old backups
chantik clean
```

<details>
<summary>📘 Complete chantik Help</summary>

```
chantik v1.0 - ChaCha20-Authenticated Backup Protection

USAGE:
    chantik [ACTION] [OPTIONS]

ACTIONS:
    backup              Perform full backup
    restore             Restore from backup
    list                List available backups
    verify              Verify backup integrity
    clean               Clean old backups (rotation)
    status              Show backup status

OPTIONS:
    -c, --config FILE   Use alternative config file
    -b, --backup FILE   Restore from specific backup file
    -s, --service NAME  Restore specific service
    -p, --password PASS Password for encryption (optional)
    -h, --help          Show this help

EXAMPLES:
    chantik backup                          # Backup all
    chantik restore                         # Restore last backup
    chantik restore -s nextcloud            # Restore specific service
    chantik restore -b /backup/file.enc     # Restore specific file
    chantik list                            # List backups
    chantik verify                          # Verify last backup
    chantik clean                           # Clean old backups
    chantik status                          # Show status
```
</details>

## 🤖 Automation (Cron Jobs)

> ⚠️ All cron jobs run in **rootless** mode. Never use `sudo` with podman commands in cron.

### User Cron Jobs (`crontab -e`)

| Schedule | Command | Purpose |
|----------|---------|---------|
| `*/5 * * * *` | `podman exec -u www-data nextcloud_app php -f /var/www/html/cron.php` | NextCloud background tasks |
| `0 1 * * *` | `podman exec pihole pihole -g && podman exec pihole pihole -f` | Pi-hole gravity update |
| `0 6 * * 0` | `/path/to/digital-independence/automation-scripts/weekly-updates/weekly_updates.sh` | Weekly service updates |
| `0 8 1 * *` | `/path/to/digital-independence/automation-scripts/monthly-recycle/monthly_recycle.sh` | Monthly service recycle |
| `0 11 * * 0` | `/path/to/digital-independence/dipen.sh prune all` | Weekly container cleanup |
| `0 2 * * *` | `/path/to/digital-independence/chantik backup` | Daily encrypted backup |

### System Cron Jobs (`sudo crontab -e`)

| Schedule | Command | Purpose |
|----------|---------|---------|
| `0 2 * * 0` | `/path/to/digital-independence/automation-scripts/cleanup-system/cleanup_system.sh` | Weekly system cleanup |
| `0 4 * * 0` | `/path/to/digital-independence/automation-scripts/system-update/system_update.sh` | Weekly system updates |

### Complete Cron Example

```bash
# Edit user crontab
crontab -e

# Add these lines
# ──────────────────────────────────────────────────────────────
# Digital Independence Automation
# ──────────────────────────────────────────────────────────────

# NextCloud cron - every 5 minutes (background jobs)
*/5 * * * * podman exec -u www-data nextcloud_app php -f /var/www/html/cron.php

# Pi-hole gravity update - daily at 1 AM (update blocklist)
0 1 * * * podman exec pihole pihole -g && podman exec pihole pihole -f

# Daily backup - 2 AM
0 2 * * * /path/to/digital-independence/chantik backup

# Weekly container updates - Sunday 6 AM
0 6 * * 0 /path/to/digital-independence/automation-scripts/weekly-updates/weekly_updates.sh

# Weekly container cleanup - Sunday 11 AM
0 11 * * 0 /path/to/digital-independence/dipen.sh prune all

# Monthly recycle - 1st at 8 AM
0 8 1 * * /path/to/digital-independence/automation-scripts/monthly-recycle/monthly_recycle.sh

# ──────────────────────────────────────────────────────────────
# System Cron (sudo crontab -e)
# ──────────────────────────────────────────────────────────────

# Weekly system cleanup - Sunday 2 AM
0 2 * * 0 /path/to/digital-independence/automation-scripts/cleanup-system/cleanup_system.sh

# Weekly system updates - Sunday 4 AM
0 4 * * 0 /path/to/digital-independence/automation-scripts/system-update/system_update.sh
```

> 📝 Replace `/path/to/digital-independence/` with your actual installation path.

## 🔒 Security Guidelines

### Initial Setup
- 🔑 Change all default passwords in `.env` files (use `dipen env <service>`)
- 🔒 Use strong, unique secrets for each service
- 🌐 Bind to `127.0.0.1` (localhost) unless external access is required
- 📁 Set `chmod 600 .env` for all environment files

### Ongoing Maintenance
- 📦 Data stored in local directories or Podman volumes (persistent)
- ⬆️ Regularly run `dipen pull` or `dipen update` for security patches
- 🔍 Monitor logs with `dipen logs [service]` for anomalies
- 📊 Enable health checks using Uptime Kuma
- 💾 Regular backups with `chantik backup`

## 🤝 Contributing

Areas for Contribution:
- Adding new services
- Bug fixes in `dipen.sh`, `chantik`, or services configuration
- Documentation improvements
- Testing on different platforms

How to Contribute:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a Pull Request

Open an [Issue](https://github.com/ricalnet/digital-independence/issues) or [Pull Request](https://github.com/ricalnet/digital-independence/pulls).

## 📜 License

### Repository
MIT License – see [LICENSE](LICENSE) file for details.