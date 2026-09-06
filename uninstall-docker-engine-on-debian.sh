#!/bin/bash
# =============================================================================
# Docker Engine Uninstallation Script for Debian
# =============================================================================

set -e

if [[ $EUID -ne 0 ]]; then
   echo "Please run this script with sudo or as the root user."
   exit 1
fi

echo "========================================"
echo " Starting Docker Engine uninstallation (Debian)"
echo "========================================"

# 1. Stop Docker service
echo "[1/7] Stopping Docker service..."
systemctl stop docker
systemctl stop docker.socket
systemctl disable docker
systemctl disable docker.socket

# 2. Uninstall Docker packages
echo "[2/7] Removing Docker Engine, CLI, containerd, and plugins..."
apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
apt autoremove -y --purge

# 3. Remove Docker repository
echo "[3/7] Removing Docker repository..."
rm -f /etc/apt/sources.list.d/docker.sources
rm -f /etc/apt/sources.list.d/docker.list

# 4. Remove Docker GPG key
echo "[4/7] Removing Docker GPG key..."
rm -f /etc/apt/keyrings/docker.asc
rmdir --ignore-fail-on-non-empty /etc/apt/keyrings

# 5. Update package index
echo "[5/7] Updating package index..."
apt update -y

# 6. Remove Docker data and configuration directories
echo "[6/7] Removing Docker data and configuration directories..."
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
rm -rf /etc/docker
rm -rf /run/docker
rm -rf /var/run/docker.sock
rm -rf ~/.docker

# 7. Remove user from docker group (optional)
echo "[7/7] Removing user from docker group..."
if [ -n "$SUDO_USER" ]; then
    USER_TO_REMOVE="$SUDO_USER"
else
    USER_TO_REMOVE="$USER"
fi

if id -nG "$USER_TO_REMOVE" | grep -qw docker; then
    gpasswd -d "$USER_TO_REMOVE" docker
    echo "User $USER_TO_REMOVE has been removed from the docker group."
else
    echo "User $USER_TO_REMOVE is not in the docker group."
fi

echo "========================================"
echo " Docker Engine uninstallation complete!"
echo "========================================"
echo "Remaining items (optional to remove):"
echo "  - /var/lib/docker (deleted)"
echo "  - /var/lib/containerd (deleted)"
echo "  - /etc/docker (deleted)"
echo "  - ~/.docker (deleted)"
echo ""
echo "If you want to remove all Docker images, containers, and volumes," 
echo "they have been removed with /var/lib/docker."
echo ""
echo "To clean up additional package dependencies:"
echo "  apt autoremove -y"
echo ""
echo "System reboot recommended for complete cleanup."
echo "========================================"