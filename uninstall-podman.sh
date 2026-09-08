#!/bin/bash

# Podman uninstallation script for Debian
# Removes all Podman components and related files

echo "=========================================="
echo "Starting Podman uninstallation on Debian"
echo "=========================================="

# 1. Reset Podman system (user level)
echo "Step 1: Resetting Podman system (user level)..."
podman system reset --force 2>/dev/null || echo "No user-level Podman system to reset"

# 2. Reset Podman system (root level)
echo "Step 2: Resetting Podman system (root level)..."
sudo podman system reset --force 2>/dev/null || echo "No root-level Podman system to reset"

# 3. Remove user-level container directories
echo "Step 3: Removing user-level container directories..."
rm -rf ~/.local/share/containers
rm -rf ~/.config/containers
rm -rf ~/.cache/containers

# 4. Remove system-wide container directories
echo "Step 4: Removing system-wide container directories..."
sudo rm -rf /var/lib/containers

# 5. Purge Podman packages
echo "Step 5: Purging Podman packages..."
sudo apt purge -y podman podman-compose podman-docker

# 6. Remove registry configuration
echo "Step 6: Removing registry configuration..."
sudo rm -rf /etc/containers/*

# 7. Remove systemd service files (system level)
echo "Step 7: Removing systemd service files (system level)..."
sudo rm -rf /usr/lib/systemd/system/podman*

# 8. Remove systemd service files (user level)
echo "Step 8: Removing systemd service files (user level)..."
sudo rm -rf /usr/lib/systemd/user/podman*

# 9. Remove binary files
echo "Step 9: Removing Podman-related binaries..."
sudo rm -rf /usr/local/bin/{crun,fuse-overlayfs,podman,runc} 2>/dev/null || echo "Some binaries not found"

# 10. Remove Podman library
echo "Step 10: Removing Podman library..."
sudo rm -rf /usr/local/lib/podman

# 11. Remove SSH keys for Podman machine
echo "Step 11: Removing SSH keys for Podman machine..."
rm -rf ~/.ssh/podman-machine-default
rm -rf ~/.ssh/podman-machine-default.pub

# 12. Remove launch daemon (macOS specific, skip if not exists)
echo "Step 12: Removing launch daemon files..."
sudo rm /Library/LaunchDaemons/com.github.containers.podman.helper-dev.plist 2>/dev/null || echo "No macOS launch daemon found"

# 13. Remove socket files
echo "Step 13: Removing Podman socket files..."
sudo rm /var/run/podman-helper-*.socket 2>/dev/null || echo "No socket files found"

# 14. Remove unused dependencies
echo "Step 14: Removing unused dependencies..."
sudo apt autoremove --purge -y

# 15. Remove residual configuration files
echo "Step 15: Removing residual configuration files..."
dpkg -l | grep '^rc' | awk '{print $2}' | sudo xargs dpkg --purge 2>/dev/null || echo "No residual packages found"

echo "=========================================="
echo "Podman uninstallation completed successfully!"
echo "=========================================="

# Optional: Verify uninstallation
echo ""
echo "Verification:"
echo "Checking if Podman is still installed..."
if command -v podman &> /dev/null; then
    echo "⚠️  Podman is still available at: $(which podman)"
    echo "You may need to remove it manually"
else
    echo "✅ Podman has been successfully removed"
fi
