#!/bin/bash

# Podman installation script for Debian
# Executes commands in the specified order

echo "=========================================="
echo "Starting Podman installation on Debian"
echo "=========================================="

# 1. Update and upgrade system
echo "Step 1: Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

# 2. Install Podman
echo "Step 2: Installing Podman..."
sudo apt install -y podman

# 3. Install supporting packages
echo "Step 3: Installing supporting packages..."
sudo apt install -y uidmap slirp4netns dbus-user-session fuse-overlayfs

# 4. Enable linger for user
echo "Step 4: Enabling linger for user $USER..."
sudo loginctl enable-linger $USER

# 5. Check linger status
echo "Step 5: Checking linger status..."
loginctl show-user $USER | grep Linger

# 6. Install podman-compose
echo "Step 6: Installing podman-compose..."
sudo apt install -y podman-compose

# 7. Check podman-compose version
echo "Step 7: Checking podman-compose version..."
podman-compose --version

# 8. Test with hello-world
echo "Step 8: Running hello-world test..."
podman run hello-world

# 9. Edit registry configuration
echo "Step 9: Editing registry configuration..."
echo "Opening /etc/containers/registries.conf with nano"
echo "Add the following line:"
echo "unqualified-search-registries = [\"docker.io\", \"ghcr.io\", \"dock.mau.dev\"]"
echo ""
sudo nano /etc/containers/registries.conf

# 10. Enable podman socket
echo "Step 10: Enabling podman.socket..."
systemctl --user enable --now podman.socket

# 11. Setup aliases for dipen.sh and chantik
echo "Step 11: Setting up aliases..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIPEN_PATH="${SCRIPT_DIR}/dipen.sh"
CHANTIK_PATH="${SCRIPT_DIR}/chantik.sh"

setup_alias() {
    local alias_name="$1"
    local script_path="$2"
    local shell_rc="$3"
    
    if [ ! -f "$script_path" ]; then
        echo "⚠️ $script_path not found, skipping $alias_name alias"
        return 1
    fi
    
    echo "Found $alias_name at: $script_path"
    chmod +x "$script_path" 2>/dev/null || true
    
    if ! grep -q "alias $alias_name=" "$shell_rc" 2>/dev/null; then
        echo "" >> "$shell_rc"
        echo "# Digital Independence - $alias_name" >> "$shell_rc"
        echo "alias $alias_name='$script_path'" >> "$shell_rc"
        echo "✅ Added $alias_name alias to $shell_rc"
    else
        echo "ℹ️ $alias_name alias already exists in $shell_rc"
    fi
}

# Setup dipen alias
if [ -f "$DIPEN_PATH" ]; then
    # Bash
    setup_alias "dipen" "$DIPEN_PATH" ~/.bashrc
    
    # Zsh
    if [ -f ~/.zshrc ]; then
        setup_alias "dipen" "$DIPEN_PATH" ~/.zshrc
    fi
else
    echo "⚠️ dipen.sh not found in current directory"
    echo "   Skipping dipen alias setup"
fi

# Setup chantik alias
if [ -f "$CHANTIK_PATH" ]; then
    # Bash
    setup_alias "chantik" "$CHANTIK_PATH" ~/.bashrc
    
    # Zsh
    if [ -f ~/.zshrc ]; then
        setup_alias "chantik" "$CHANTIK_PATH" ~/.zshrc
    fi
else
    echo "⚠️ chantik not found in current directory"
    echo "   Skipping chantik alias setup"
fi

echo ""
echo "💡 To use the aliases, either:"
echo "   - Restart your terminal, or"
echo "   - Run: source ~/.bashrc (or source ~/.zshrc)"
echo ""
echo "📝 Examples after setup:"
echo "   dipen up portainer"
echo "   dipen list"
echo "   dipen env nextcloud"
echo "   chantik backup"
echo "   chantik restore -s nextcloud"
echo "   chantik list"

echo "=========================================="
echo "Podman installation completed successfully!"
echo "=========================================="