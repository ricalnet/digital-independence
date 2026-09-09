<div align="center">

# Digital Independence

**Kembalikan kendali atas kehidupan digital Anda, satu container pada satu waktu.**

[![Lisensi: MIT](https://img.shields.io/badge/Lisensi-MIT-kuning.svg)](https://opensource.org/licenses/MIT)
[![Podman](https://img.shields.io/badge/Podman-5+-2496ED?logo=podman&logoColor=putih)](https://podman.io/)
[![Rootless](https://img.shields.io/badge/Rootless-✅_Didukung-8A2BE2?logo=podman&logoColor=putih)](https://podman.io/docs/rootless)
[![Arsitektur](https://img.shields.io/badge/Arsitektur-amd64_|_arm64-4EAA25?logo=linux&logoColor=putih)](https://hub.docker.com/)
[![Pemeliharaan](https://img.shields.io/badge/Dipelihara%3F-ya-hijau.svg)](https://github.com/ricalnet/digital-independence/graphs/commit-activity)
[![Cadangan](https://img.shields.io/badge/Cadangan-ChaCha20--Poly1305-8A2BE2?logo=openssl&logoColor=putih)](https://github.com/ricalnet/digital-independence#-chantik-encrypted-backup--restore)

</div>

## 📌 Apa itu Dipen?

Dipen adalah solusi self-hosting lengkap yang menyediakan konfigurasi `podman-compose` untuk 24+ layanan open-source populer. Ini menghilangkan ketergantungan pada layanan cloud pihak ketiga dengan memberi Anda kendali penuh atas data dan infrastruktur Anda.

Filosofi Inti:
- 🔒 Kepemilikan Data Total — Data Anda tetap di perangkat keras Anda, selamanya
- 💰 Tanpa Biaya Berulang — Bayar sekali untuk perangkat keras, gratis selamanya
- 🔄 Kebebasan Penuh — Ganti, modifikasi, atau ganti layanan apa pun kapan saja
- 🎯 Pembelajaran Praktis — Bangun keterampilan DevOps nyata melalui pengalaman langsung
- 🚀 Siap Deploy — Clone, instal, dan jalankan

## 🏗️ Dukungan Arsitektur

| Arsitektur | Platform | Status |
|------------|----------|--------|
| `linux/amd64` | Intel/AMD, x86_64 | ✅ Didukung |
| `linux/arm64` | Raspberry Pi 4/5, Apple M1/M2/M3, AWS Graviton | ✅ Didukung |

## 📦 Layanan Tersedia (24 Layanan)

### 🔐 Keamanan & Autentikasi

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| Wazuh | `wazuh/` | 443 | Pemantauan keamanan dan deteksi ancaman |
| Pi-hole | `pi-hole/` | 53, 8080 | Pemblokiran iklan seluruh jaringan dan penyaringan DNS |
| Vaultwarden | `vaultwarden/` | 8000 | Pengelola kata sandi ringan kompatibel Bitwarden |
| Authentik | `authentik/` | 9000, 9443 | Manajemen identitas dan akses lengkap (SSO) |

### 🤖 AI & Pembelajaran Mesin

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| Open WebUI | `open-webui/` | 3000 | Antarmuka obrolan untuk LLM Ollama |

> Konfigurasikan dengan `OLLAMA_BASE_URL` di `.env`

### 🖥️ Manajemen & Pemantauan

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| Dashdot | `dashdot/` | 3001 | Dasbor server modern dengan metrik sistem |
| Homarr | `homarr/` | 7575 | Dasbor beranda yang bersih dan dapat disesuaikan |
| ntfy | `ntfy/` | 8010 | Layanan notifikasi pub/sub sederhana |
| Uptime Kuma | `uptime-kuma/` | 9442 | Pemantauan uptime self-hosted |
| Portainer | `portainer/` | 9444 | UI manajemen container untuk Podman/Docker |

### 💬 Komunikasi (Ekosistem Matrix)

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| Synapse | `synapse/` | 8008, 8448 | Homeserver Matrix untuk obrolan terdesentralisasi |
| Element Web | `element-web/` | 8009 | Klien web untuk Matrix |
| Jembatan Mautrix | `synapse/mautrix/` | - | Jembatan Telegram & WhatsApp (compose.yaml tunggal) |

### 🌐 Pencarian & Penerjemahan

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| LibreTranslate | `libretranslate/` | 5001 | Penerjemahan mesin open-source |
| SearXNG | `searxng/` | 8888 | Mesin pencari metasearch yang menghormati privasi |

### 📁 Manajemen Media & Konten

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| Immich | `immich/` | 2283 | Alternatif Google Photos (self-hosted) |
| Navidrome | `navidrome/` | 4533 | Server streaming musik (kompatibel Subsonic) |
| Nextcloud | `nextcloud/` | 5000 | Suite produktivitas lengkap (file, kalender, kontak) |
| Jellyfin | `jellyfin/` | 8096, 8920 | Server media lengkap (alternatif Plex) |

### 🔗 Manajemen Tautan

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| YOURLS | `yourls/` | 8001 | Pengecil URL dengan analitik |
| LinkStack | `linkstack/` | 8003 | Manajer berbagi tautan dan bookmark |

### 📚 Manajemen Pengetahuan

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| MediaWiki | `wiki/` | 8002 | Mesin wiki gaya Wikipedia |

### 🐘 Media Sosial

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| Mastodon | `mastodon/` | 4000, 4001 | Jaringan sosial terfederasi (alternatif Twitter) |

> Mastodon memerlukan `.env` (Podman) dan `.env.production` (konfigurasi Mastodon)

### 🦊 Manajemen Kode & Repositori

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| Forgejo | `forgejo/` | 3002 | Layanan Git self-hosted (alternatif Gitea) |

Catatan Penting:
- 🔧 Gunakan `dipen env <layanan>` untuk membuat dan mengedit file `.env` secara otomatis
- 🏷️ Layanan menggunakan tag `latest` secara default — sematkan versi untuk stabilitas jika diperlukan
- 🌐 Layanan terikat ke `127.0.0.1` (localhost) secara default untuk keamanan
- 📖 Panduan deployment dan penyesuaian lengkap tersedia di [Wiki Resmi](https://git.ricalnet.my.id/rical/digital-independence/wiki)

## 📋 Prasyarat

| Persyaratan | Versi Minimum | Catatan |
|-------------|---------------|--------|
| Podman | 5.4+ | Mesin container rootless |
| podman-compose | v1.3+ | Orkestrasi Compose untuk Podman |
| Git | Terbaru | Kontrol versi |
| OS | Linux / macOS / WSL2 | Sistem kompatibel POSIX |
| Memori | 4GB+ | Tergantung layanan yang berjalan |
| Penyimpanan | 50GB+ | Berdasarkan layanan dan volume data |

## 🚀 Mulai Cepat (3 Langkah)

### Langkah 1: Clone Repositori
```bash
git clone https://git.ricalnet.my.id/rical/digital-independence.git
cd digital-independence
```

### Langkah 2: Instal Podman dan Dependensi
```bash
./install-podman-on-debian.sh
```

> **📖 Panduan Instalasi Lengkap:** Untuk petunjuk detail tentang konfigurasi registri, pengaturan environment, dan penyesuaian khusus layanan, silakan merujuk ke [Wiki Deployment](https://git.ricalnet.my.id/rical/digital-independence/wiki).

### Langkah 3: Konfigurasi & Mulai Layanan
```bash
# Lihat daftar layanan yang tersedia
dipen list

# Buat dan edit file .env untuk layanan yang diinginkan (contoh: nextcloud)
dipen env nextcloud

# Mulai layanan
dipen up nextcloud

# Untuk memulai semua layanan
dipen all up
```

## ⚙️ dipen: Orkestrasi Layanan

`dipen` adalah alat baris perintah utama untuk mengelola semua layanan.

### Contoh Penggunaan

```bash
# Pencocokan wildcard
dipen env n*              # Edit semua layanan yang dimulai dengan 'n'
dipen up n*               # Mulai semua layanan yang dimulai dengan 'n'

# Banyak layanan
dipen env nextcloud immich authentik

# Editor kustom
EDITOR=vim dipen env immich

# Semua layanan
dipen all up              # Mulai semuanya
dipen all down            # Hentikan semuanya
```

<details>
<summary>📘 Bantuan Lengkap dipen</summary>

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
```
</details>

## 🌐 Mengekspos Layanan Secara Eksternal

### 🧅 Layanan Tersembunyi Tor
Menyediakan akses anonim melalui jaringan Tor.
- 📖 [Panduan Implementasi Tor](https://docs.ricalnet.my.id/posts/panduan-implementasi-hidden-service-tor/)

### ☁️ Cloudflare Tunnel
Mengakses layanan tanpa membuka port firewall.
- 📖 [Panduan Cloudflare Tunnel](https://docs.ricalnet.my.id/posts/panduan-lengkap-mengonfigurasi-cloudflare-tunnel-untuk-ekspos-layanan-lokal/)

## 💾 Chantik: Pencadangan & Pemulihan Terenkripsi

[Chantik](https://git.ricalnet.my.id/rical/chantik) adalah alat Perlindungan Cadangan ChaCha20-Terautentikasi yang dibuat khusus untuk dipen.

### ✨ Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 🔐 Enkripsi Terautentikasi | ChaCha20-Poly1305 (utama) dengan fallback AES-256-CBC |
| 🔑 Derivasi Kunci Kuat | PBKDF2 dengan iterasi yang dapat dikonfigurasi (default: 600.000) |
| 🔗 Deduplikasi | Dukungan nonce tetap untuk enkripsi deterministik |
| 🗜️ Kompresi | Gzip dengan level yang dapat dikonfigurasi (1-9) |
| 🐳 Dukungan Docker | Pencadangan dan pemulihan volume Docker yang mulus |
| 🔄 Cadangan Incremental | Hemat penyimpanan dan percepat pencadangan |
| 📊 Retensi Cerdas | Kebijakan retensi harian, mingguan, dan bulanan |
| 🔔 Notifikasi Real-time | Peringatan instan melalui ntfy.sh |
| ✅ Verifikasi Integritas | Verifikasi checksum SHA256 untuk setiap cadangan |
| 🔒 Keamanan | Izin yang dapat dikonfigurasi dan penguncian proses |
| 📝 Pencatatan Log Komprehensif | Log terperinci untuk audit dan pemecahan masalah |

## 🤖 Otomatisasi (Cron Jobs)

> ⚠️ Semua cron job berjalan dalam mode **rootless**. Jangan pernah menggunakan `sudo` dengan perintah podman di cron.

### Cron Job Pengguna (`crontab -e`)

| Jadwal | Perintah | Tujuan |
|--------|----------|--------|
| `*/5 * * * *` | `podman exec -u www-data nextcloud_app php -f /var/www/html/cron.php` | Tugas latar belakang NextCloud |
| `0 1 * * *` | `podman exec pihole pihole -g && podman exec pihole pihole -f` | Pembaruan gravity Pi-hole |
| `0 6 * * 0` | `/path/to/digital-independence/automation-scripts/weekly-updates/weekly_updates.sh` | Pembaruan layanan mingguan |
| `0 8 1 * *` | `/path/to/digital-independence/automation-scripts/monthly-recycle/monthly_recycle.sh` | Daur ulang layanan bulanan |
| `0 11 * * 0` | `/path/to/digital-independence/dipen.sh prune all` | Pembersihan container mingguan |
| `0 2 * * *` | `/path/to/digital-independence/chantik backup` | Pencadangan terenkripsi harian |

### Cron Job Sistem (`sudo crontab -e`)

| Jadwal | Perintah | Tujuan |
|--------|----------|--------|
| `0 2 * * 0` | `/path/to/digital-independence/automation-scripts/cleanup-system/cleanup_system.sh` | Pembersihan sistem mingguan |
| `0 4 * * 0` | `/path/to/digital-independence/automation-scripts/system-update/system_update.sh` | Pembaruan sistem mingguan |

### Contoh Cron Lengkap

```bash
# Edit crontab pengguna
crontab -e

# Tambahkan baris berikut
# ──────────────────────────────────────────────────────────────
# Otomatisasi Digital Independence
# ──────────────────────────────────────────────────────────────

# Cron NextCloud - setiap 5 menit (tugas latar belakang)
*/5 * * * * podman exec -u www-data nextcloud_app php -f /var/www/html/cron.php

# Pembaruan gravity Pi-hole - setiap hari jam 1 pagi (perbarui daftar blokir)
0 1 * * * podman exec pihole pihole -g && podman exec pihole pihole -f

# Pencadangan harian - jam 2 pagi
0 2 * * * /path/to/digital-independence/chantik backup

# Pembaruan container mingguan - Minggu jam 6 pagi
0 6 * * 0 /path/to/digital-independence/automation-scripts/weekly-updates/weekly_updates.sh

# Pembersihan container mingguan - Minggu jam 11 siang
0 11 * * 0 /path/to/digital-independence/dipen.sh prune all

# Daur ulang bulanan - tanggal 1 jam 8 pagi
0 8 1 * * /path/to/digital-independence/automation-scripts/monthly-recycle/monthly_recycle.sh

# ──────────────────────────────────────────────────────────────
# Cron Sistem (sudo crontab -e)
# ──────────────────────────────────────────────────────────────

# Pembersihan sistem mingguan - Minggu jam 2 pagi
0 2 * * 0 /path/to/digital-independence/automation-scripts/cleanup-system/cleanup_system.sh

# Pembaruan sistem mingguan - Minggu jam 4 pagi
0 4 * * 0 /path/to/digital-independence/automation-scripts/system-update/system_update.sh
```

> 📝 Ganti `/path/to/digital-independence/` dengan jalur instalasi Anda yang sebenarnya.

## 🔒 Panduan Keamanan

### Pengaturan Awal
- 🔑 Ubah semua kata sandi default di file `.env` (gunakan `dipen env <layanan>`)
- 🔒 Gunakan secret yang kuat dan unik untuk setiap layanan
- 🌐 Ikat ke `127.0.0.1` (localhost) kecuali akses eksternal diperlukan
- 📁 Atur `chmod 600 .env` untuk semua file lingkungan

### Pemeliharaan Berkelanjutan
- 📦 Data disimpan di direktori lokal atau volume Podman (persisten)
- ⬆️ Jalankan `dipen pull` atau `dipen update` secara teratur untuk tambalan keamanan
- 🔍 Pantau log dengan `dipen logs [layanan]` untuk anomali
- 📊 Aktifkan health check menggunakan Uptime Kuma
- 💾 Pencadangan rutin dengan `chantik backup`

## 📜 Lisensi

### Repositori
Lisensi MIT – lihat file [LICENSE](LICENSE) untuk detail.