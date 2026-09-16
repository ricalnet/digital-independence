<div align="center">

# Digital Independence

**Take back control of your digital life, one container at a time.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Podman](https://img.shields.io/badge/Podman-5+-2496ED?logo=podman&logoColor=white)](https://podman.io/)
[![Rootless](https://img.shields.io/badge/Rootless-✅_Supported-8A2BE2?logo=podman&logoColor=white)](https://podman.io/docs/rootless)
[![Architecture](https://img.shields.io/badge/Architecture-amd64_|_arm64-4EAA25?logo=linux&logoColor=white)](https://hub.docker.com/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/ricalnet/digital-independence/graphs/commit-activity)
[![Backup](https://img.shields.io/badge/Backup-ChaCha20--Poly1305-8A2BE2?logo=openssl&logoColor=white)](https://github.com/ricalnet/digital-independence#-chantik-encrypted-backup--restore)
[![Firewall](https://img.shields.io/badge/Firewall-IPC_(Iptables)-FF6B6B?logo=linux&logoColor=white)](https://git.ricalnet.my.id/rical/digital-independence/wiki/Iptables-Port-Controller)
[![Hardening](https://img.shields.io/badge/Hardening-✅_Active-success?logo=shield&logoColor=white)](#-hardening--resource-limits)

</div>

## 📌 What is Dipen?

Dipen is a self-hosting solution that provides `podman-compose` configurations for 25+ popular open-source services. It eliminates dependency on third-party cloud services by giving you full control over your data and infrastructure.

Core Philosophy:
- 🔒 Total Data Ownership — Your data stays on your hardware, forever
- 💰 No Recurring Costs — Pay once for hardware, free forever
- 🔄 Complete Freedom — Swap, modify, or replace any service anytime
- 🎯 Hands-On Learning — Build real DevOps skills through direct experience
- 🚀 Ready to Deploy — Clone, install, and run
- 🔥 Integrated Security — Built-in firewall with IPC (Iptables Controller)
- 🛡️ Default Hardening — All services are hardened with resource limits

## 🆚 Comparison with Similar Projects

| Aspect | Dipen | YunoHost | Cloudron | Umbrel | Coolify |
|-------|-----------|----------|----------|--------|---------|
| Model | Curated Compose collection | App store + system integration | Managed app store | Personal cloud OS | Self-hosted PaaS |
| Runtime | Podman (rootless) | Docker | Docker | Docker | Docker |
| Native rootless (no root daemon) | ✅ Yes | ❌ No | ❌ No | ❌ No | ❌ No |
| Built-in firewall (default-deny) | ✅ IPC (Iptables) | ⚠️ Manual | ⚠️ Limited | ⚠️ Limited | ⚠️ Manual |
| ChaCha20 encrypted backup | ✅ Chantik | ⚠️ Generic | ✅ (paid feature) | ⚠️ Generic | ⚠️ Generic |
| License | MIT | Open source | Proprietary (Freemium) | Open source | Open source |
| Services | 25+ curated | 500+ | 100+ | 120+ | Unlimited |
| Difficulty | Intermediate | Low | Low | Very low | Intermediate–High |
| Best for | CLI users who want full control | Beginners who want instant everything | Small teams who want a finished product | Non-technical users | Developers deploying their own apps |

> [!TIP]
> Want instant usability? Use YunoHost/Cloudron. Want full control + built-in security + learning DevOps? Use Dipen.

## 🏗️ Architecture Support

| Architecture | Platform | Status |
|------------|----------|--------|
| `linux/amd64` | Intel/AMD, x86_64 | ✅ Supported |
| `linux/arm64` | Raspberry Pi 4/5, Apple M1/M2/M3, AWS Graviton | ✅ Supported |

## 📦 Available Services (25+ Services)

### 🔐 Security & Authentication

| Service | Directory | Port | Purpose |
|---------|-----------|------|--------|
| Wazuh | `wazuh/` | 443 | Security monitoring and threat detection |
| Pi-hole | `pi-hole/` | 53, 8080 | Network-wide ad blocking and DNS filtering |
| Vaultwarden | `vaultwarden/` | 8000 | Lightweight Bitwarden-compatible password manager |
| Authentik | `authentik/` | 9000, 9443 | Full identity and access management (SSO) |

> [!WARNING]
> Wazuh has not been tested on Podman since the migration from Docker. The previous Wazuh configuration was tested and worked well on Docker, but has not been re-verified after migrating to Podman. Use with caution and report any issues.

### 🛡️ Privacy & Anonymity

| Service | Directory | Port | Purpose |
|---------|-----------|------|--------|
| obfs4 Bridge | `obfs4-bridge/` | 8443, 9443 | obfs4 Tor bridge to help access Tor on censored networks |

### 🤖 AI & Machine Learning

| Service | Directory | Port | Purpose |
|---------|-----------|------|--------|
| Open WebUI | `open-webui/` | 3000 | Chat interface for Ollama LLM |

> [!TIP]
> Configure Open WebUI with `OLLAMA_BASE_URL` in `.env`

### 🖥️ Management & Monitoring

| Service | Directory | Port | Purpose |
|---------|-----------|------|--------|
| Dashdot | `dashdot/` | 3001 | Modern server dashboard with system metrics |
| Homarr | `homarr/` | 7575 | Clean and customizable homepage dashboard |
| ntfy | `ntfy/` | 8010 | Simple pub/sub notification service |
| Uptime Kuma | `uptime-kuma/` | 9442 | Self-hosted uptime monitoring |
| Portainer | `portainer/` | 9444 | Container management UI for Podman/Docker |

### 💬 Communication (Matrix Ecosystem)

| Service | Directory | Port | Purpose |
|---------|-----------|------|--------|
| Synapse | `synapse/` | 8008, 8448 | Matrix homeserver for decentralized chat |
| Element Web | `element-web/` | 8009 | Web client for Matrix |
| Mautrix Bridges | `synapse/mautrix/` | - | Telegram & WhatsApp bridges (single compose.yaml) |

### 🌐 Search & Translation

| Service | Directory | Port | Purpose |
|---------|-----------|------|--------|
| LibreTranslate | `libretranslate/` | 5001 | Open-source machine translation |
| SearXNG | `searxng/` | 8888 | Privacy-respecting metasearch engine |

### 📁 Media & Content Management

| Service | Directory | Port | Purpose |
|---------|-----------|------|--------|
| Immich | `immich/` | 2283 | Google Photos alternative (self-hosted) |
| Navidrome | `navidrome/` | 4533 | Music streaming server (Subsonic-compatible) |
| Nextcloud | `nextcloud/` | 5000 | Complete productivity suite (files, calendar, contacts) |
| Jellyfin | `jellyfin/` | 8096, 8920 | Full media server (Plex alternative) |

### 🔗 Link Management

| Service | Directory | Port | Purpose |
|---------|-----------|------|--------|
| YOURLS | `yourls/` | 8001 | URL shortener with analytics |
| LinkStack | `linkstack/` | 8003 | Link sharing and bookmark manager |

### 📚 Knowledge Management

| Service | Directory | Port | Purpose |
|---------|-----------|------|--------|
| MediaWiki | `wiki/` | 8002 | Wikipedia-style wiki engine |

### 🐘 Social Media

| Service | Directory | Port | Purpose |
|---------|-----------|------|--------|
| Mastodon | `mastodon/` | 4000, 4001 | Federated social network (Twitter alternative) |

> [!WARNING]
> Mastodon has not been tested on Podman since the migration from Docker. The previous Mastodon configuration was tested and worked well on Docker, but has not been re-verified after migrating to Podman. Use with caution and report any issues.

> [!IMPORTANT]
> Mastodon requires `.env` (Podman) and `.env.production` (Mastodon configuration)

### 🦊 Code & Repository Management

| Service | Directory | Port | Purpose |
|---------|-----------|------|--------|
| Forgejo | `forgejo/` | 3002 | Self-hosted Git service (Gitea alternative) |

### 📡 IoT & Messaging

| Service | Directory | Port | Purpose |
|---------|-----------|------|--------|
| Mosquitto | `mqtt-broker/` | 1883, 9001 | MQTT broker for IoT and messaging |
### 📈 Monitoring & Observability

| Service | Directory | Port | Purpose |
|---------|-----------|------|--------|
| Prometheus | `monitoring/` | 9090 | Metric collection and time-series storage |
| Grafana | `monitoring/` | 3000 | Metric visualization and dashboards |
| Node Exporter | `monitoring/` | 9100 | Host system metrics (CPU, memory, disk, network) |
| Podman Exporter | `monitoring/` | 9882 | Podman container metrics |
| Alertmanager | `monitoring/` | 9093 | Alert management and routing |

> [!NOTE]
> The monitoring stack consists of 5 containers in a single `compose.yaml` in the `monitoring/` directory. All services bind to `127.0.0.1` by default and are hardened with resource limits, `no-new-privileges`, and `cap_drop: ALL`.

> [!TIP]
> Configure Prometheus via `monitoring/prometheus/prometheus.yml`, alert rules in `monitoring/prometheus/rules/`, and Alertmanager in `monitoring/alertmanager/alertmanager.yml`. All configuration files are mounted as read-only.

> [!IMPORTANT]
> `podman-exporter` requires access to the Podman socket. Make sure `PODMAN_SOCKET_PATH` in `.env` matches your Podman socket path (default: `/run/user/1000/podman/podman.sock`). For rootless users, the socket is usually located at `$XDG_RUNTIME_DIR/podman/podman.sock`.

Important Notes:
- 🔧 Use `dipen env <service>` to automatically create and edit `.env` files
- 🏷️ Services use the `latest` tag by default — pin versions for stability if needed
- 🌐 Services bind to `127.0.0.1` (localhost) by default for security
- 🛡️ All services are hardened with resource limits, security opt, and cap drop
- 📖 Complete deployment and customization guides are available in the [Official Wiki](https://git.ricalnet.my.id/rical/digital-independence/wiki)

## 🔥 IPC: Iptables Port Controller

IPC is the built-in firewall management tool for controlling network access to your self-hosted services.

### Security Philosophy

IPC enforces a **default-deny** policy for incoming traffic:
- 🚫 **INPUT DROP** — All incoming connections are denied by default
- ✅ **OUTPUT ACCEPT** — Outgoing connections are allowed (server can access the internet)
- 🚫 **FORWARD DROP** — Routing between interfaces is disabled

### Key Features

| Feature | Description |
|-------|-----------|
| 🔌 Port Management | Easily enable/disable ports |
| 🌐 Dual-stack | Full IPv4 and IPv6 support |
| 📦 Persistence | Rules persist after reboot |
| 🔄 Auto-restore | Rules are restored on boot |
| 📊 Status Monitoring | View active rules |
| 🧹 Reset | Return to default policy |

### 📖 Complete Documentation

For detailed guides on firewall configuration, deployment examples, and troubleshooting:
- 📚 [Wiki: Iptables Port Controller](https://git.ricalnet.my.id/rical/digital-independence/wiki/Iptables-Port-Controller-%E2%80%94-Firewall)

## 📋 Prerequisites

| Requirement | Minimum Version | Notes |
|-------------|---------------|--------|
| Podman | 5.4+ | Rootless container engine |
| podman-compose | v1.3+ | Compose orchestration for Podman |
| Git | Latest | Version control |
| OS | Linux / macOS / WSL2 | POSIX-compatible systems |
| Memory | 4GB+ | Depends on running services |
| Storage | 50GB+ | Based on services and data volumes |

## 🚀 Quick Start (4 Steps)

### Step 1: Clone the Repository
```bash
git clone https://git.ricalnet.my.id/rical/digital-independence.git
cd digital-independence
```

### Step 2: Install Podman and Dependencies
```bash
./install-podman-on-debian.sh
```

> [!TIP]
> For detailed instructions on registry configuration, environment setup, and service-specific customization, please refer to the [Deployment Wiki](https://git.ricalnet.my.id/rical/digital-independence/wiki/Mulai-Cepat).

### Step 3: Configure & Start Services
```bash
# View the list of available services
dipen list

# Create and edit the .env file for the desired service (example: nextcloud)
dipen env nextcloud

# Start the service
dipen up nextcloud

# To start all services
dipen all up
```

### Step 4: Configure Firewall
```bash
# Setup persistence and enable required ports
sudo ipc setup-persistence
sudo ipc init
sudo ipc enable 22     # SSH
sudo ipc enable 5353   # DNS
```

## ⚙️ dipen: Service Orchestration

`dipen` is the main command-line tool for managing all services.

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

# Quick navigation
dipen cd nextcloud        # Change to Nextcloud service directory
dipen cd volume           # Change to Podman volume directory
dipen cd volume nextcloud # Change + filter Nextcloud volumes
```

<details>
<summary>📘 Full dipen Help</summary>

```
dipen v1.1.1 - Podman Orchestration Tool for Digital Independence
Issues: https://git.ricalnet.my.id/rical/digital-independence/issues 

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
    check-version       Check latest stable image versions
    cd <service>        Change directory to service directory
    cd volume           Change directory to podman volume directory

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
    dipen check-version
    dipen check-version nextcloud immich
    dipen cd nextcloud
    dipen cd volume
    dipen cd volume nextcloud
```
</details>

## 🌐 Exposing Services Externally

### 🔥 Integrated Firewall (IPC)
Use IPC to manage ports exposed to the public:
```bash
# Show firewall status
sudo ipc status

# Enable port for external services
sudo ipc enable 443   # HTTPS
```

### 🧅 Tor Hidden Services
Provides anonymous access through the Tor network.
- 📖 [Tor Implementation Guide](https://docs.ricalnet.my.id/posts/panduan-implementasi-hidden-service-tor/)

### 🛡️ obfs4 Bridge (Tor Bridge)
Run a private **obfs4 bridge** to help Tor users in regions with strict network censorship. This bridge makes your Tor traffic look like random traffic, making it harder to block by firewalls or DPI (Deep Packet Inspection).

Features:
- 🔐 Runs on rootless Podman — no root privileges needed
- 🌐 Uses ports 8443 (OR) and 9443 (PT) to be safe on rootless Podman
- 📦 Integrated with IPC to open ports automatically
- 🔄 Auto-restart via `podman-compose` (`restart: unless-stopped`)
- 📝 Saves installation logs and bridge line to `logs/obfs4_installation.log`

Automated installation:
```bash
./auto-install-obfs4.sh
```

The script will:
1. Install `ipc` and Podman
2. Create `.env` interactively (EMAIL & NICKNAME)
3. Create the `obfs4_bridge_external_network` network
4. Run the `obfs4-bridge` container
5. Wait for Tor bootstrap to complete (3 minutes)
6. Extract the fingerprint and assemble the bridge line
7. Save the result to `logs/obfs4_installation.log`

Example generated bridge line:
```
obfs4 111.122.133.144:9443 9F394AE597C053CC566FB204F0FB7F3D078FDDC1 cert=dZhB1rJ7QOK/tRFHRnd5o28tONVCp/R/0x7rDLmcNb59qoR/ERS5xlYMOOqDBA9KTk46ag iat-mode=0
```

How to use in Tor Browser:
1. Open Tor Browser → Settings → Connection → Bridges
2. Select "Use a bridge" → "Provide a bridge I know"
3. Paste the bridge line above
4. Click Connect

Ports to open (via IPC):
```bash
sudo ipc enable 8443 both tcp   # OR Port
sudo ipc enable 9443 both tcp   # PT Port (obfs4)
```

> [!NOTE]
> The `obfs4_bridgeline.txt` file inside the container contains a template with `<IP ADDRESS>`, `<PORT>`, and `<FINGERPRINT>` placeholders. The `auto-install-obfs4.sh` script will replace them automatically with the actual values.
>
> A newly started bridge takes several hours–24 hours to be registered in the Tor Project's BridgeDB. For personal use, the bridge line can be used directly via "Provide a bridge I know".

### ☁️ Cloudflare Tunnel
Access services without opening firewall ports.
- 📖 [Cloudflare Tunnel Guide](https://docs.ricalnet.my.id/posts/panduan-lengkap-mengonfigurasi-cloudflare-tunnel-untuk-ekspos-layanan-lokal/)

## 💾 Chantik: Encrypted Backup & Restore

[Chantik](https://git.ricalnet.my.id/rical/chantik) is a ChaCha20-Authenticated Backup Protection tool built specifically for dipen.

### ✨ Key Features

| Feature | Description |
|-------|-----------|
| 🔐 Authenticated Encryption | ChaCha20-Poly1305 (primary) with AES-256-CBC fallback |
| 🔑 Strong Key Derivation | PBKDF2 with configurable iterations (default: 600,000) |
| 🔗 Deduplication | Fixed nonce support for deterministic encryption |
| 🗜️ Compression | Gzip with configurable level (1-9) |
| 🐳 Docker Support | Seamless Docker volume backup and restore |
| 🔄 Incremental Backup | Storage-efficient and faster backups |
| 📊 Smart Retention | Daily, weekly, and monthly retention policies |
| 🔔 Real-time Notifications | Instant alerts via ntfy.sh |
| ✅ Integrity Verification | SHA256 checksum verification for every backup |
| 🔒 Security | Configurable permissions and process locking |
| 📝 Comprehensive Logging | Detailed logs for auditing and troubleshooting |

## 🤖 Automation (Cron Jobs)

> [!WARNING]
> All cron jobs run in **rootless** mode. Never use `sudo` with podman commands in cron.

### User Cron Jobs (`crontab -e`)

| Schedule | Command | Purpose |
|--------|----------|--------|
| `*/5 * * * *` | `podman exec -u www-data nextcloud_app php -f /var/www/html/cron.php` | NextCloud background tasks |
| `0 1 * * *` | `podman exec pihole pihole -g && podman exec pihole pihole -f` | Pi-hole gravity update |
| `0 6 * * 0` | `/path/to/digital-independence/automation-scripts/weekly-updates/weekly_updates.sh` | Weekly service updates |
| `0 8 1 * *` | `/path/to/digital-independence/automation-scripts/monthly-recycle/monthly_recycle.sh` | Monthly service recycle |
| `0 11 * * 0` | `/path/to/digital-independence/dipen.sh prune all` | Weekly container cleanup |
| `0 2 * * *` | `/path/to/digital-independence/chantik backup` | Daily encrypted backup |

### System Cron Jobs (`sudo crontab -e`)

| Schedule | Command | Purpose |
|--------|----------|--------|
| `0 2 * * 0` | `/path/to/digital-independence/automation-scripts/cleanup-system/cleanup_system.sh` | Weekly system cleanup |
| `0 4 * * 0` | `/path/to/digital-independence/automation-scripts/system-update/system_update.sh` | Weekly system update |

### Complete Cron Example

```bash
# Edit user crontab
crontab -e

# Add the following lines
# ──────────────────────────────────────────────────────────────
# Digital Independence Automation
# ──────────────────────────────────────────────────────────────

# NextCloud Cron - every 5 minutes (background tasks)
*/5 * * * * podman exec -u www-data nextcloud_app php -f /var/www/html/cron.php

# Pi-hole gravity update - daily at 1 AM (update blocklists)
0 1 * * * podman exec pihole pihole -g && podman exec pihole pihole -f

# Daily backup - at 2 AM
0 2 * * * /path/to/digital-independence/chantik backup

# Weekly container updates - Sunday at 6 AM
0 6 * * 0 /path/to/digital-independence/automation-scripts/weekly-updates/weekly_updates.sh

# Weekly container cleanup - Sunday at 11 AM
0 11 * * 0 /path/to/digital-independence/dipen.sh prune all

# Monthly recycle - 1st of the month at 8 AM
0 8 1 * * /path/to/digital-independence/automation-scripts/monthly-recycle/monthly_recycle.sh

# ──────────────────────────────────────────────────────────────
# System Cron (sudo crontab -e)
# ──────────────────────────────────────────────────────────────

# Weekly system cleanup - Sunday at 2 AM
0 2 * * 0 /path/to/digital-independence/automation-scripts/cleanup-system/cleanup_system.sh

# Weekly system update - Sunday at 4 AM
0 4 * * 0 /path/to/digital-independence/automation-scripts/system-update/system_update.sh
```

> [!TIP]
> Replace `/path/to/digital-independence/` with your actual installation path.

## 🔒 Security Guide

### Initial Setup
- 🔑 Change all default passwords in `.env` files (use `dipen env <service>`)
- 🔒 Use strong and unique secrets for each service
- 🌐 Bind to `127.0.0.1` (localhost) unless external access is needed
- 📁 Set `chmod 600 .env` for all environment files
- 🔥 Configure the firewall with IPC — only open necessary ports
- 🛡️ Verify hardening with `podman inspect <container>`

### Firewall Best Practices

```bash
# 1. Setup persistence
sudo ipc setup-persistence

# 2. Initialize (default-deny)
sudo ipc init

# 3. Open specific service ports
sudo ipc enable 5000  # Nextcloud
sudo ipc enable 5353  # Pi-Hole
sudo ipc enable 8443  # obfs4 OR Port
sudo ipc enable 9443  # obfs4 PT Port

# 4. Verify status
sudo ipc status

# 5. Save rules (automatic, but can be manual)
sudo ipc persist
```

### Ongoing Maintenance
- 📦 Data is stored in local directories or Podman volumes (persistent)
- ⬆️ Run `dipen pull` or `dipen update` regularly for security patches
- 🔍 Monitor logs with `dipen logs [service]` for anomalies
- 📊 Enable health checks using Uptime Kuma
- 💾 Regular backups with `chantik backup`
- 🔥 Audit firewall rules periodically with `ipc status`
- 🛡️ Do not share obfs4 bridge lines publicly — private bridges are safer and more stable
- 🔐 Audit resource limits periodically with `podman stats`

## 📜 License

### Repository
MIT License – see the [LICENSE](LICENSE) file for details.

## 📚 Resources

| Resource | Link |
|-------------|--------|
| Official Wiki | [Digital Independence Wiki](https://git.ricalnet.my.id/rical/digital-independence/wiki) |
| IPC Documentation | [Iptables Port Controller](https://git.ricalnet.my.id/rical/digital-independence/wiki/Iptables-Port-Controller-%E2%80%94-Firewall) |
| Chantik | [Encrypted Backup Tool](https://git.ricalnet.my.id/rical/digital-independence/wiki/Chantik+%E2%80%94+ChaCha20-Authenticated+Backup+Protection.-) |