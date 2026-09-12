<div align="center">

# Digital Independence

**Kembalikan kendali atas kehidupan digital Anda, satu container pada satu waktu.**

[![Lisensi: MIT](https://img.shields.io/badge/Lisensi-MIT-kuning.svg)](https://opensource.org/licenses/MIT)
[![Podman](https://img.shields.io/badge/Podman-5+-2496ED?logo=podman&logoColor=putih)](https://podman.io/)
[![Rootless](https://img.shields.io/badge/Rootless-✅_Didukung-8A2BE2?logo=podman&logoColor=putih)](https://podman.io/docs/rootless)
[![Arsitektur](https://img.shields.io/badge/Arsitektur-amd64_|_arm64-4EAA25?logo=linux&logoColor=putih)](https://hub.docker.com/)
[![Pemeliharaan](https://img.shields.io/badge/Dipelihara%3F-ya-hijau.svg)](https://github.com/ricalnet/digital-independence/graphs/commit-activity)
[![Cadangan](https://img.shields.io/badge/Cadangan-ChaCha20--Poly1305-8A2BE2?logo=openssl&logoColor=putih)](https://github.com/ricalnet/digital-independence#-chantik-encrypted-backup--restore)
[![Firewall](https://img.shields.io/badge/Firewall-IPC_(Iptables)-FF6B6B?logo=linux&logoColor=putih)](https://git.ricalnet.my.id/rical/digital-independence/wiki/Iptables-Port-Controller)
[![Hardening](https://img.shields.io/badge/Hardening-✅_Aktif-success?logo=shield&logoColor=putih)](#-hardening--resource-limits)

</div>

## 📌 Apa itu Dipen?

Dipen adalah solusi self-hosting lengkap yang menyediakan konfigurasi `podman-compose` untuk 25+ layanan open-source populer. Ini menghilangkan ketergantungan pada layanan cloud pihak ketiga dengan memberi Anda kendali penuh atas data dan infrastruktur Anda.

Filosofi Inti:
- 🔒 Kepemilikan Data Total — Data Anda tetap di perangkat keras Anda, selamanya
- 💰 Tanpa Biaya Berulang — Bayar sekali untuk perangkat keras, gratis selamanya
- 🔄 Kebebasan Penuh — Ganti, modifikasi, atau ganti layanan apa pun kapan saja
- 🎯 Pembelajaran Praktis — Bangun keterampilan DevOps nyata melalui pengalaman langsung
- 🚀 Siap Deploy — Clone, instal, dan jalankan
- 🔥 Keamanan Terintegrasi — Firewall bawaan dengan IPC (Iptables Controller)
- 🛡️ Hardening Default — Semua layanan sudah di-hardening dengan resource limits

## 🏗️ Dukungan Arsitektur

| Arsitektur | Platform | Status |
|------------|----------|--------|
| `linux/amd64` | Intel/AMD, x86_64 | ✅ Didukung |
| `linux/arm64` | Raspberry Pi 4/5, Apple M1/M2/M3, AWS Graviton | ✅ Didukung |

## 📦 Layanan Tersedia (25+ Layanan)

### 🔐 Keamanan & Autentikasi

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| Wazuh | `wazuh/` | 443 | Pemantauan keamanan dan deteksi ancaman |
| Pi-hole | `pi-hole/` | 53, 8080 | Pemblokiran iklan seluruh jaringan dan penyaringan DNS |
| Vaultwarden | `vaultwarden/` | 8000 | Pengelola kata sandi ringan kompatibel Bitwarden |
| Authentik | `authentik/` | 9000, 9443 | Manajemen identitas dan akses lengkap (SSO) |

### 🛡️ Privasi & Anonimitas

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| obfs4 Bridge | `obfs4-bridge/` | 8443, 9443 | Tor bridge obfs4 untuk membantu akses Tor di jaringan tersensor |

### 🤖 AI & Pembelajaran Mesin

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| Open WebUI | `open-webui/` | 3000 | Antarmuka obrolan untuk LLM Ollama |

> [!TIP]
> Konfigurasikan Open WebUI dengan `OLLAMA_BASE_URL` di `.env`

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

> [!IMPORTANT]
> Mastodon memerlukan `.env` (Podman) dan `.env.production` (konfigurasi Mastodon)

### 🦊 Manajemen Kode & Repositori

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| Forgejo | `forgejo/` | 3002 | Layanan Git self-hosted (alternatif Gitea) |

### 📡 IoT & Messaging

| Layanan | Direktori | Port | Tujuan |
|---------|-----------|------|--------|
| Mosquitto | `mqtt-broker/` | 1883, 9001 | MQTT broker untuk IoT dan messaging |

Catatan Penting:
- 🔧 Gunakan `dipen env <layanan>` untuk membuat dan mengedit file `.env` secara otomatis
- 🏷️ Layanan menggunakan tag `latest` secara default — sematkan versi untuk stabilitas jika diperlukan
- 🌐 Layanan terikat ke `127.0.0.1` (localhost) secara default untuk keamanan
- 🛡️ Semua layanan sudah di-hardening dengan resource limits, security opt, dan cap drop
- 📖 Panduan deployment dan penyesuaian lengkap tersedia di [Wiki Resmi](https://git.ricalnet.my.id/rical/digital-independence/wiki)

## 🔥 IPC: Iptables Port Controller

IPC adalah alat manajemen firewall bawaan untuk mengontrol akses jaringan ke layanan self-hosted Anda.

### Filosofi Keamanan

IPC menerapkan kebijakan **default-deny** untuk lalu lintas masuk:
- 🚫 **INPUT DROP** — Semua koneksi masuk ditolak secara default
- ✅ **OUTPUT ACCEPT** — Koneksi keluar diizinkan (server dapat mengakses internet)
- 🚫 **FORWARD DROP** — Routing antar antarmuka dinonaktifkan

### Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 🔌 Manajemen Port | Aktifkan/nonaktifkan port dengan mudah |
| 🌐 Dual-stack | Dukungan penuh IPv4 dan IPv6 |
| 📦 Persistence | Aturan tetap berlaku setelah reboot |
| 🔄 Auto-restore | Aturan dipulihkan saat boot |
| 📊 Status Monitoring | Lihat aturan yang aktif |
| 🧹 Reset | Kembali ke kebijakan default |

### 📖 Dokumentasi Lengkap

Untuk panduan mendetail tentang konfigurasi firewall, contoh deployment, dan troubleshooting:
- 📚 [Wiki: Iptables Port Controller](https://git.ricalnet.my.id/rical/digital-independence/wiki/Iptables-Port-Controller-%E2%80%94-Firewall)

## 📋 Prasyarat

| Persyaratan | Versi Minimum | Catatan |
|-------------|---------------|--------|
| Podman | 5.4+ | Mesin container rootless |
| podman-compose | v1.3+ | Orkestrasi Compose untuk Podman |
| Git | Terbaru | Kontrol versi |
| OS | Linux / macOS / WSL2 | Sistem kompatibel POSIX |
| Memori | 4GB+ | Tergantung layanan yang berjalan |
| Penyimpanan | 50GB+ | Berdasarkan layanan dan volume data |

## 🚀 Mulai Cepat (4 Langkah)

### Langkah 1: Clone Repositori
```bash
git clone https://git.ricalnet.my.id/rical/digital-independence.git
cd digital-independence
```

### Langkah 2: Instal Podman dan Dependensi
```bash
./install-podman-on-debian.sh
```

> [!TIP]
> Untuk petunjuk detail tentang konfigurasi registri, pengaturan environment, dan penyesuaian khusus layanan, silakan merujuk ke [Wiki Deployment](https://git.ricalnet.my.id/rical/digital-independence/wiki/Mulai-Cepat).

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

### Langkah 4: Konfigurasi Firewall
```bash
# Setup persistence dan aktifkan port yang diperlukan
sudo ipc setup-persistence
sudo ipc init
sudo ipc enable 22     # SSH
sudo ipc enable 5353   # DNS
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

# Navigasi cepat
dipen cd nextcloud        # Pindah ke direktori layanan Nextcloud
dipen cd volume           # Pindah ke direktori volume Podman
dipen cd volume nextcloud # Pindah + filter volume Nextcloud
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

## 🌐 Mengekspos Layanan Secara Eksternal

### 🔥 Firewall Terintegrasi (IPC)
Gunakan IPC untuk mengatur port yang terbuka ke publik:
```bash
# Tampilkan status firewall
sudo ipc status

# Aktifkan port untuk layanan eksternal
sudo ipc enable 443   # HTTPS
```

### 🧅 Layanan Tersembunyi Tor
Menyediakan akses anonim melalui jaringan Tor.
- 📖 [Panduan Implementasi Tor](https://docs.ricalnet.my.id/posts/panduan-implementasi-hidden-service-tor/)

### 🛡️ obfs4 Bridge (Tor Bridge)
Menjalankan **obfs4 bridge** pribadi untuk membantu pengguna Tor di wilayah dengan sensor jaringan ketat. Bridge ini membuat lalu lintas Tor Anda terlihat seperti trafik acak, sehingga lebih sulit diblokir oleh firewall atau DPI (Deep Packet Inspection).

Fitur:
- 🔐 Berjalan di Podman rootless — tanpa perlu hak akses root
- 🌐 Menggunakan port 8443 (OR) dan 9443 (PT) agar aman di rootless Podman
- 📦 Terintegrasi dengan IPC untuk membuka port secara otomatis
- 🔄 Auto-restart via `podman-compose` (`restart: unless-stopped`)
- 📝 Menyimpan log instalasi dan bridge line ke `logs/obfs4_installation.log`

Instalasi otomatis:
```bash
./auto-install-obfs4.sh
```

Script akan:
1. Menginstal `ipc` dan Podman
2. Membuat `.env` secara interaktif (EMAIL & NICKNAME)
3. Membuat network `obfs4_bridge_external_network`
4. Menjalankan container `obfs4-bridge`
5. Menunggu bootstrap Tor selesai (3 menit)
6. Mengekstrak fingerprint dan menyusun bridge line
7. Menyimpan hasil ke `logs/obfs4_installation.log`

Contoh bridge line yang dihasilkan:
```
obfs4 111.122.133.144:9443 9F394AE597C053CC566FB204F0FB7F3D078FDDC1 cert=dZhB1rJ7QOK/tRFHRnd5o28tONVCp/R/0x7rDLmcNb59qoR/ERS5xlYMOOqDBA9KTk46ag iat-mode=0
```

Cara pakai di Tor Browser:
1. Buka Tor Browser → Settings → Connection → Bridges
2. Pilih "Use a bridge" → "Provide a bridge I know"
3. Paste bridge line di atas
4. Klik Connect

Port yang perlu dibuka (via IPC):
```bash
sudo ipc enable 8443 both tcp   # OR Port
sudo ipc enable 9443 both tcp   # PT Port (obfs4)
```

> [!NOTE]
> File `obfs4_bridgeline.txt` di dalam container berisi template dengan placeholder `<IP ADDRESS>`, `<PORT>`, dan `<FINGERPRINT>`. Script `auto-install-obfs4.sh` akan menggantinya secara otomatis dengan nilai asli.
>
> Bridge yang baru pertama kali jalan butuh beberapa jam–24 jam untuk terdaftar di BridgeDB Tor Project. Untuk penggunaan pribadi, bridge line bisa langsung dipakai via "Provide a bridge I know".

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

> [!WARNING]
> Semua cron job berjalan dalam mode **rootless**. Jangan pernah menggunakan `sudo` dengan perintah podman di cron.

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

> [!TIP]
> Ganti `/path/to/digital-independence/` dengan jalur instalasi Anda yang sebenarnya.

## 🔒 Panduan Keamanan

### Pengaturan Awal
- 🔑 Ubah semua kata sandi default di file `.env` (gunakan `dipen env <layanan>`)
- 🔒 Gunakan secret yang kuat dan unik untuk setiap layanan
- 🌐 Ikat ke `127.0.0.1` (localhost) kecuali akses eksternal diperlukan
- 📁 Atur `chmod 600 .env` untuk semua file lingkungan
- 🔥 Konfigurasikan firewall dengan IPC — hanya buka port yang diperlukan
- 🛡️ Verifikasi hardening dengan `podman inspect <container>`

### Firewall Best Practices

```bash
# 1. Setup persistence
sudo ipc setup-persistence

# 2. Inisialisasi (default-deny)
sudo ipc init

# 3. Buka port layanan spesifik
sudo ipc enable 5000  # Nextcloud
sudo ipc enable 5353  # Pi-Hole
sudo ipc enable 8443  # obfs4 OR Port
sudo ipc enable 9443  # obfs4 PT Port

# 4. Verifikasi status
sudo ipc status

# 5. Simpan aturan (otomatis, tapi bisa manual)
sudo ipc persist
```

### Pemeliharaan Berkelanjutan
- 📦 Data disimpan di direktori lokal atau volume Podman (persisten)
- ⬆️ Jalankan `dipen pull` atau `dipen update` secara teratur untuk tambalan keamanan
- 🔍 Pantau log dengan `dipen logs [layanan]` untuk anomali
- 📊 Aktifkan health check menggunakan Uptime Kuma
- 💾 Pencadangan rutin dengan `chantik backup`
- 🔥 Audit aturan firewall secara berkala dengan `ipc status`
- 🛡️ Jangan bagikan bridge line obfs4 ke publik — bridge pribadi lebih aman dan stabil
- 🔐 Audit resource limits secara berkala dengan `podman stats`

## 📜 Lisensi

### Repositori
Lisensi MIT – lihat file [LICENSE](LICENSE) untuk detail.

## 📚 Sumber Daya

| Sumber Daya | Tautan |
|-------------|--------|
| Wiki Resmi | [Digital Independence Wiki](https://git.ricalnet.my.id/rical/digital-independence/wiki) |
| Dokumentasi IPC | [Iptables Port Controller](https://git.ricalnet.my.id/rical/digital-independence/wiki/Iptables-Port-Controller-%E2%80%94-Firewall) |
| Dokumentasi Deployment | [Deployment Guide](https://git.ricalnet.my.id/rical/digital-independence/wiki/Panduan-Penerapan-Digital-Independence) |
| Chantik | [Encrypted Backup Tool](https://git.ricalnet.my.id/rical/digital-independence/wiki/Chantik+%E2%80%94+ChaCha20-Authenticated+Backup+Protection.-) |