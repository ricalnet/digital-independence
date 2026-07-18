<div align="center">

![Digital Independence Banner](thumbnail.png)

# Digital Independence

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-29.4+-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![GitHub Issues](https://img.shields.io/github/issues/ricalnet/digital-independence)](https://github.com/ricalnet/digital-independence/issues)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/ricalnet/digital-independence/graphs/commit-activity)

</div>

## Summary
Digital Independence is a collection of ready-to-use Docker Compose configurations for running various self-hosted services on your own infrastructure. This project is designed to empower individuals and small organizations to manage their data, communication, and daily applications independently — not to completely abandon commercial services, but to ensure you have control, privacy, and choice.

> *"Take back control of your digital life, one container at a time."*

## ✨ Available Services

| Icon | Service Name | Directory Path | Port | Brief Description |
|------|---------------|----------------|------|-------------------|
| 📊 | **Dashdot** | `dashdot/` | 3001 | Lightweight and informative system dashboard. |
| 💬 | **Element Web** | `element-web/` | 8009 | Modern web client for the Matrix communication protocol. |
| 🗂️ | **Homarr** | `homarr/` | 7575 | Modular dashboard to manage all your services. |
| 🖼️ | **Immich** | `immich-app/` | 2283 | Self-hosted photo and video management solution (Google Photos alternative). |
| 🎥 | **Jellyfin** | `jellyfin/` | 8096, 8920 | Open-source media server for streaming movies, music, and TV. |
| 🌐 | **LibreTranslate** | `LibreTranslate/` | 5001 | Offline translation engine that respects privacy. |
| 🐘 | **Mastodon** | `mastodon/` | 4000, 4001 | Federated social networking server (Twitter/X alternative). |
| 🎵 | **Navidrome** | `navidrome/` | 4533 | Modern music streaming server with Subsonic support. |
| ☁️ | **Nextcloud** | `nextcloud-docker/` | 5000 | Complete cloud storage and collaboration platform. |
| 🔔 | **ntfy** | `ntfy/` | 8010 | Simple push notifications via HTTP, ideal for script integration. |
| 🤖 | **Open WebUI** | `open-webui/` | 3000, 11434 | Intuitive LLM interface, supports Ollama and OpenAI API. |
| 🛡️ | **Pi-hole** | `pi-hole/` | 53, 8080 | DNS-level ad and tracker filtering for your entire network. |
| 🐳 | **Portainer** | `portainer/` | 9443 | Docker container management via web interface. |
| 🔍 | **SearXNG** | `searxng-docker/` | 8888 | Privacy-respecting metasearch engine. |
| 📨 | **Synapse** | `synapse/` | 8008, 8448 | Reference server for the Matrix communication network. |
| ⏱️ | **Uptime Kuma** | `uptime-kuma/` | 9442 | Service status monitoring with real-time notifications. |
| 🔐 | **Vaultwarden** | `vaultwarden/` | 8000 | Bitwarden-compatible password management server, lightweight version. |
| 📚 | **MediaWiki** | `wiki/` | 8002 | Wiki platform used by Wikipedia. |
| 🔗 | **YOURLS** | `yourls/` | 8001 | Self-hosted URL shortening service. |

> Ports listed are the default ports on the host. Some services are only bound to `127.0.0.1` (localhost) for security reasons. Modify the configuration in each service's `docker-compose.yml` to bind to `0.0.0.0` or change the port.

Additional Synapse services (bridges):
- `synapse:mautrix-telegram` – Telegram bridge
- `synapse:mautrix-whatsapp` – WhatsApp bridge

## 📋 Prerequisites

Before starting, ensure your system meets the following requirements:

- Docker Engine version 29.4+ (recommended)
- Git to clone the repository
- (Optional) `whiptail` or `dialog` for interactive menu
- Linux / macOS operating system (Windows with WSL2 is also supported)

## 🚀 Getting Started

1. Clone the repository
   ```bash
   cd ~/
   git clone https://github.com/ricalnet/digital-independence.git
   cd digital-independence
   ```

2. Install Docker Engine (if not already available)
   - For Debian:
     ```bash
     ./install-docker-engine-on-debian.sh
     ```
   - For Ubuntu:
     ```bash
     ./install-docker-engine-on-ubuntu.sh
     ```

3. Prepare environment files (`.env`) for services that require them
   ```bash
   # Example for Immich
   cp immich-app/.env.example immich-app/.env
   nano immich-app/.env   # adjust as needed
   ```

4. Manage services using the `sovereign.sh` script

## ⚙️ Using `sovereign.sh`

`sovereign.sh` is a command-line tool designed to simplify management of all services in one command.

### Interactive Menu (easiest)
```bash
./sovereign.sh -i
```
Or run without arguments: `./sovereign.sh`

### Quick Command Examples

| Purpose | Command |
|---------|---------|
| Start a single service | `./sovereign.sh portainer` |
| Start all services | `./sovereign.sh -a up` |
| Stop a service | `./sovereign.sh -d portainer` |
| Restart services | `./sovereign.sh -r portainer vaultwarden` |
| Update images and restart | `./sovereign.sh recycle synapse` |
| Update without service downtime | `./sovereign.sh update immich` |
| Simulate commands (dry-run) | `./sovereign.sh -n up portainer` |

> For Synapse sub-services, use `synapse:mautrix-telegram` or `synapse:mautrix-whatsapp`.

### Full Help Guide
```bash
./sovereign.sh -h
```

<details>
<summary>📘 Full help guide: <code>./sovereign.sh -h</code></summary>

```bash
./sovereign.sh -h
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

By default, services are only accessible from localhost. To access them securely from the internet (without opening raw ports to the public), this repository supports two approaches:

### 🧅 Tor Hidden Service (.onion)
Anonymous access through the Tor network.  
🔗 [Tor Hidden Service Implementation Guide](https://docs.ricalnet.my.id/posts/panduan-implementasi-hidden-service-tor/)

### ☁️ Cloudflare Tunnel
Access through Cloudflare without opening firewall ports.  
🔗 [Cloudflare Tunnel Configuration Guide](https://docs.ricalnet.my.id/posts/panduan-lengkap-mengonfigurasi-cloudflare-tunnel-untuk-ekspos-layanan-lokal/)

## ⚠️ Security & Maintenance Guidelines

To keep your system secure and stable, follow these recommendations:

- Immediately change passwords and secrets in `.env` files.
- Container data is stored in local directories or Docker volumes.
- Use the `--pull` option and read upstream project changelogs before major updates.
- For standard internet access, set up Nginx Proxy Manager or Traefik (configuration is not included in this repository).

## 🤝 Contributing

Here are some areas where you can help:

- Adding configurations for new services
- Fixing bugs or improving features in `sovereign.sh`
- Completing or improving documentation

Please open an [Issue](https://github.com/ricalnet/digital-independence/issues) or submit a [Pull Request](https://github.com/ricalnet/digital-independence/pulls).

## 📜 License

This repository uses the [MIT License](LICENSE). However, each included service has its own license. Please comply with the license terms of each upstream project.