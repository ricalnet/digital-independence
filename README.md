![alt text](thumbnail.png)

## Ringkasan
Digital Independence adalah kumpulan konfigurasi Docker Compose siap pakai untuk menjalankan berbagai layanan self-hosted di infrastruktur Anda sendiri. Proyek ini dirancang untuk memberdayakan individu maupun organisasi kecil agar dapat mengelola data, komunikasi, dan aplikasi sehari-hari secara mandiri — bukan untuk sepenuhnya meninggalkan layanan komersial, tetapi untuk memastikan Anda memiliki kendali, privasi, dan pilihan.

> *"Take back control of your digital life, one container at a time."*

## ✨ Layanan yang Tersedia

| Ikon | Nama Layanan | Path Direktori | Port | Deskripsi Singkat |
|------|---------------|----------------|------|-------------------|
| 📊 | **Dashdot** | `dashdot/` | 3001 | Dashboard sistem yang ringan dan informatif. |
| 💬 | **Element Web** | `element-web/` | 8009 | Klien web modern untuk protokol komunikasi Matrix. |
| 🗂️ | **Homarr** | `homarr/` | 7575 | Dashboard modular untuk mengelola semua layanan Anda. |
| 🖼️ | **Immich** | `immich-app/` | 2283 | Solusi self-hosted untuk manajemen foto dan video (alternatif Google Photos). |
| 🎥 | **Jellyfin** | `jellyfin/` | 8096, 8920 | Server media open-source untuk streaming film, musik, dan TV. |
| 🌐 | **LibreTranslate** | `LibreTranslate/` | 5001 | Mesin penerjemah offline yang menghormati privasi. |
| 🐘 | **Mastodon** | `mastodon/` | 4000, 4001 | Server jejaring sosial federasi (alternatif Twitter/X). |
| 🎵 | **Navidrome** | `navidrome/` | 4533 | Server streaming musik modern dengan dukungan Subsonic. |
| ☁️ | **Nextcloud** | `nextcloud-docker/` | 5000 | Platform kolaborasi dan penyimpanan awan lengkap. |
| 🔔 | **ntfy** | `ntfy/` | 8010 | Notifikasi push sederhana melalui HTTP, ideal untuk integrasi dengan skrip. |
| 🤖 | **Open WebUI** | `open-webui/` | 3000, 11434 | Antarmuka LLM yang intuitif, mendukung Ollama dan API OpenAI. |
| 🛡️ | **Pi-hole** | `pi-hole/` | 53, 8080 | Pemfilter iklan dan tracker di tingkat DNS untuk seluruh jaringan. |
| 🐳 | **Portainer** | `portainer/` | 9443 | Manajemen kontainer Docker melalui antarmuka web. |
| 🔍 | **SearXNG** | `searxng-docker/` | 8888 | Mesin pencari metasearch yang tidak melacak pengguna. |
| 📨 | **Synapse** | `synapse/` | 8008, 8448 | Server referensi untuk jaringan komunikasi Matrix. |
| ⏱️ | **Uptime Kuma** | `uptime-kuma/` | 9442 | Monitoring status layanan dengan notifikasi real-time. |
| 🔐 | **Vaultwarden** | `vaultwarden/` | 8000 | Server manajemen kata sandi kompatibel Bitwarden, versi ringan. |
| 📚 | **MediaWiki** | `wiki/` | 8002 | Platform wiki yang digunakan oleh Wikipedia. |
| 🔗 | **YOURLS** | `yourls/` | 8001 | Layanan pemendek tautan yang dapat dihosting sendiri. |

> Port yang tercantum adalah port default pada host. Beberapa layanan hanya terikat ke `127.0.0.1` (localhost) demi alasan keamanan. Ubah konfigurasi di `docker-compose.yml` masing-masing layanan untuk mengikat ke `0.0.0.0` atau mengubah port.

Layanan tambahan pada Synapse (bridge):
- `synapse:mautrix-telegram` – Penghubung ke Telegram
- `synapse:mautrix-whatsapp` – Penghubung ke WhatsApp

## 📋 Prasyarat

Sebelum memulai, pastikan sistem telah memenuhi persyaratan berikut:

- Docker Engine versi 29.4+ (direkomendasikan)
- Git untuk meng-clone repositori
- (Opsional) `whiptail` atau `dialog` untuk menu interaktif
- Sistem operasi Linux / macOS (Windows dengan WSL2 juga didukung)

## 🚀 Memulai

1. Clone repositori
   ```bash
   cd ~/
   git clone https://github.com/ricalnet/digital-independence.git
   cd digital-independence
   ```

2. Instal Docker Engine (jika belum tersedia)
   - Untuk Debian:
     ```bash
     ./install-docker-engine-on-debian.sh
     ```
   - Untuk Ubuntu:
     ```bash
     ./install-docker-engine-on-ubuntu.sh
     ```

3. Siapkan file lingkungan (`.env`) untuk layanan yang membutuhkannya
   ```bash
   # Contoh untuk Immich
   cp immich-app/.env.example immich-app/.env
   nano immich-app/.env   # sesuaikan dengan kebutuhan
   ```

4. Kelola layanan menggunakan skrip `sovereign.sh`

## ⚙️ Menggunakan `sovereign.sh`

`sovereign.sh` adalah alat command-line yang dirancang untuk menyederhanakan manajemen semua layanan dalam satu perintah.

### Menu Interaktif (termudah)
```bash
./sovereign.sh -i
```
Atau jalankan tanpa argumen: `./sovereign.sh`

### Contoh Perintah Cepat

| Tujuan | Perintah |
|--------|----------|
| Jalankan satu layanan | `./sovereign.sh portainer` |
| Jalankan semua layanan | `./sovereign.sh -a up` |
| Hentikan layanan | `./sovereign.sh -d portainer` |
| Mulai ulang layanan | `./sovereign.sh -r portainer vaultwarden` |
| Perbarui image dan restart | `./sovereign.sh recycle synapse` |
| Perbarui tanpa hentikan layanan | `./sovereign.sh update immich` |
| Simulasi perintah (dry-run) | `./sovereign.sh -n up portainer` |

> Penamaan layanan khusus untuk layanan turunan Synapse, gunakan `synapse:mautrix-telegram` atau `synapse:mautrix-whatsapp`.

### Panduan Lengkap
```bash
./sovereign.sh -h
```

<details>
<summary>📘 Panduan lengkap: <code>./sovereign.sh -h</code></summary>

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

## 🌐 Mengekspos Layanan ke Internet

Secara default, layanan hanya dapat diakses dari localhost. Untuk mengaksesnya dari internet dengan aman (tanpa membuka port mentah ke publik), repositori ini mendukung dua pendekatan:

### 🧅 Tor Hidden Service (.onion)
Akses anonim melalui jaringan Tor.  
🔗 [Panduan Implementasi Hidden Service Tor](https://docs.ricalnet.my.id/posts/panduan-implementasi-hidden-service-tor/)

### ☁️ Cloudflare Tunnel
Akses melalui Cloudflare tanpa membuka port firewall.  
🔗 [Panduan Mengonfigurasi Cloudflare Tunnel](https://docs.ricalnet.my.id/posts/panduan-lengkap-mengonfigurasi-cloudflare-tunnel-untuk-ekspos-layanan-lokal/)

## ⚠️ Panduan Keamanan & Pemeliharaan

Agar sistem tetap aman dan stabil, ikuti rekomendasi berikut:

- Segera ubah kata sandi dan kunci rahasia di file `.env`.
- Data kontainer disimpan di direktori lokal atau Docker volume.
- Gunakan opsi `--pull` dan baca changelog proyek upstream sebelum pembaruan besar.
- Jika ingin akses internet standar, pasang Nginx Proxy Manager atau Traefik (konfigurasi tidak disertakan dalam repositori ini).

## 🤝 Kontribusi

Berikut beberapa area yang dapat dibantu:

- Menambahkan konfigurasi untuk layanan baru
- Memperbaiki bug atau meningkatkan fitur di `sovereign.sh`
- Melengkapi atau merapikan dokumentasi

Silakan buka [Issue](https://github.com/ricalnet/digital-independence/issues) atau kirim [Pull Request](https://github.com/ricalnet/digital-independence/pulls).

## 📜 Lisensi

Repositori ini menggunakan [Lisensi MIT](LICENSE). Namun, setiap layanan yang disertakan memiliki lisensi masing-masing. Harap patuhi ketentuan lisensi dari setiap proyek upstream.