#!/bin/bash
# =============================================================================
# Docker Engine Installation Script for Debian
# Based on official Docker guide (https://docs.docker.com/engine/install/debian/)
# =============================================================================

set -e

if [[ $EUID -ne 0 ]]; then
   echo "Please run this script with sudo or as the root user."
   exit 1
fi

echo "========================================"
echo " Starting Docker Engine installation (Debian)"
echo "========================================"

# 1. Update package index and install dependencies
echo "[1/5] Updating package index and installing ca-certificates, curl..."
apt update -y
apt install -y ca-certificates curl

# 2. Prepare keyring directory and download official Docker GPG key for Debian
echo "[2/5] Adding official Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# 3. Add Docker repository to APT sources
echo "[3/5] Adding Docker repository..."
# Detect release codename (Debian codename) and system architecture
codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
arch=$(dpkg --print-architecture)

tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $codename
Components: stable
Architectures: $arch
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# 4. Update package index again after adding the repository
echo "[4/5] Updating package index with Docker repository..."
apt update -y

# 5. Install Docker Engine and supporting components
echo "[5/5] Installing Docker Engine, CLI, containerd, and plugins..."
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "========================================"
echo " Docker Engine installation complete!"
echo "========================================"
echo "You can verify by running: docker --version"