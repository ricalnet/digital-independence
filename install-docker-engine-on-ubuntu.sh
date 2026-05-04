#!/bin/bash
# =============================================================================
# Skrip Instalasi Docker Engine di Ubuntu
# Berdasarkan panduan resmi Docker (https://docs.docker.com/engine/install/ubuntu/)
# =============================================================================

set -e

if [[ $EUID -ne 0 ]]; then
   echo "Harap jalankan skrip ini dengan sudo atau sebagai pengguna root."
   exit 1
fi

echo "========================================"
echo " Mulai instalasi Docker Engine"
echo "========================================"

# 1. Perbarui indeks paket dan pasang dependensi
echo "[1/5] Memperbarui indeks paket dan menginstal ca-certificates, curl..."
apt update -y
apt install -y ca-certificates curl

# 2. Siapkan direktori keyring dan unduh GPG key resmi Docker
echo "[2/5] Menambahkan GPG key resmi Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# 3. Tambahkan repositori Docker ke sumber APT
echo "[3/5] Menambahkan repositori Docker..."
# Mendeteksi nama kode rilis (Ubuntu codename) dan arsitektur sistem
codename=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
arch=$(dpkg --print-architecture)

tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $codename
Components: stable
Architectures: $arch
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# 4. Perbarui indeks paket lagi setelah menambah repositori
echo "[4/5] Memperbarui indeks paket dengan repositori Docker..."
apt update -y

# 5. Instal Docker Engine dan komponen pendukung
echo "[5/5] Menginstal Docker Engine, CLI, containerd, dan plugin..."
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "========================================"
echo " Instalasi Docker Engine selesai!"
echo "========================================"
echo "Anda dapat memverifikasi dengan menjalankan: docker --version"
