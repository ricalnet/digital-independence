#!/bin/bash

set -o pipefail

echo "=========================================="
echo "Starting Podman uninstallation"
echo "=========================================="

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_ID_LIKE="$ID_LIKE"
        OS_NAME="$PRETTY_NAME"
    else
        echo "❌ Cannot detect distribution (/etc/os-release not found)"
        exit 1
    fi

    case "$OS_ID" in
        debian|ubuntu|linuxmint|pop|raspbian)
            PKG_MGR="apt"
            DISTRO_FAMILY="debian"
            ;;
        rhel|centos|rocky|almalinux|fedora|ol)
            if command -v dnf >/dev/null 2>&1; then
                PKG_MGR="dnf"
            else
                PKG_MGR="yum"
            fi
            DISTRO_FAMILY="rhel"
            ;;
        *)
            case "$OS_ID_LIKE" in
                *debian*|*ubuntu*) PKG_MGR="apt"; DISTRO_FAMILY="debian" ;;
                *rhel*|*fedora*|*centos*)
                    if command -v dnf >/dev/null 2>&1; then PKG_MGR="dnf"; else PKG_MGR="yum"; fi
                    DISTRO_FAMILY="rhel"
                    ;;
                *)
                    echo "❌ Unsupported distribution: $OS_NAME"
                    exit 1
                    ;;
            esac
            ;;
    esac

    echo "🖥️  Detected: $OS_NAME"
    echo "📦 Package manager: $PKG_MGR"
    echo "🐧 Family: $DISTRO_FAMILY"
    echo ""
}

detect_distro

remove_pkgs() {
    case "$PKG_MGR" in
        apt) sudo apt remove -y --purge "$@" ;;
        dnf) sudo dnf remove -y "$@" ;;
        yum) sudo yum remove -y "$@" ;;
    esac
}

autoremove_pkgs() {
    case "$PKG_MGR" in
        apt) sudo apt autoremove -y --purge ;;
        dnf) sudo dnf autoremove -y ;;
        yum) sudo yum autoremove -y ;;
    esac
}

echo "Step 1: Stopping podman.socket (if running)..."
systemctl --user disable --now podman.socket 2>/dev/null || true
systemctl --user disable --now podman.service 2>/dev/null || true

echo "Step 2: Removing dipen wrapper from shell rc files..."

MARKER_BEGIN="# >>> dipen wrapper >>>"
MARKER_END="# <<< dipen wrapper <<<"

remove_dipen_block() {
    local shell_rc="$1"
    local shell_name="$2"

    if [ ! -f "$shell_rc" ]; then
        echo "ℹ️  $shell_rc not found, skipping $shell_name"
        return 0
    fi

    cp "$shell_rc" "${shell_rc}.bak.$(date +%Y%m%d_%H%M%S)"
    echo "📦 Backed up $shell_rc"

    if grep -qF "$MARKER_BEGIN" "$shell_rc" 2>/dev/null; then
        sed -i.bak "/^${MARKER_BEGIN}$/,/^${MARKER_END}$/d" "$shell_rc"
        echo "🗑️  Removed dipen wrapper block from $shell_rc"
    else
        echo "ℹ️  No dipen wrapper block found in $shell_rc"
    fi

    if grep -qE "^\s*alias\s+dipen=" "$shell_rc" 2>/dev/null; then
        sed -i.bak -E "/^\s*alias\s+dipen=/d" "$shell_rc"
        echo "🗑️  Removed old 'alias dipen=' from $shell_rc"
    fi

    if grep -qE "^# Digital Independence - dipen$" "$shell_rc" 2>/dev/null; then
        sed -i.bak -E "/^# Digital Independence - dipen$/d" "$shell_rc"
        echo "🗑️  Removed old comment from $shell_rc"
    fi

    rm -f "${shell_rc}.bak" 2>/dev/null
}

if [ -f ~/.bashrc ]; then
    remove_dipen_block ~/.bashrc "bash"
fi
if [ -f ~/.zshrc ]; then
    remove_dipen_block ~/.zshrc "zsh"
fi

echo "Step 3: Removing podman-compose venv and symlink..."
VENV_DIR="$HOME/.local/share/podman-compose-venv"
if [ -d "$VENV_DIR" ]; then
    rm -rf "$VENV_DIR"
    echo "🗑️  Removed $VENV_DIR"
else
    echo "ℹ️  $VENV_DIR not found, skipping"
fi

if [ -L /usr/local/bin/podman-compose ] || [ -f /usr/local/bin/podman-compose ]; then
    sudo rm -f /usr/local/bin/podman-compose
    echo "🗑️  Removed /usr/local/bin/podman-compose"
else
    echo "ℹ️  /usr/local/bin/podman-compose not found, skipping"
fi

echo "Step 4: Removing ipc from /usr/local/bin..."
if [ -f /usr/local/bin/ipc ]; then
    sudo rm -f /usr/local/bin/ipc
    echo "🗑️  Removed /usr/local/bin/ipc"
else
    echo "ℹ️  /usr/local/bin/ipc not found, skipping"
fi

echo "Step 5: Disabling linger for user $USER..."
sudo loginctl disable-linger $USER 2>/dev/null || true
echo "✅ Linger disabled"

echo "Step 6: Removing container data (optional)..."
if [ -d "$HOME/.local/share/containers" ]; then
    read -p "Do you want to remove ~/.local/share/containers (all images, volumes, containers)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/.local/share/containers"
        echo "🗑️  Removed ~/.local/share/containers"
    else
        echo "⏭️  Kept ~/.local/share/containers"
    fi
else
    echo "ℹ️  ~/.local/share/containers not found, skipping"
fi

if [ -d "$HOME/.config/containers" ]; then
    read -p "Do you want to remove ~/.config/containers (custom config)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/.config/containers"
        echo "🗑️  Removed ~/.config/containers"
    else
        echo "⏭️  Kept ~/.config/containers"
    fi
else
    echo "ℹ️  ~/.config/containers not found, skipping"
fi

echo "Step 7: Removing podman packages..."
case "$DISTRO_FAMILY" in
    debian)
        remove_pkgs podman podman-compose uidmap slirp4netns fuse-overlayfs 2>/dev/null || true
        ;;
    rhel)
        remove_pkgs podman podman-compose fuse-overlayfs slirp4netns 2>/dev/null || true
        ;;
esac

echo "Step 8: Autoremoving unused packages..."
autoremove_pkgs

echo "Step 9: Cleaning up leftover config files..."
case "$DISTRO_FAMILY" in
    debian)
        sudo apt purge -y podman podman-compose 2>/dev/null || true
        ;;
    rhel)
        sudo rm -rf /etc/containers /usr/share/containers 2>/dev/null || true
        ;;
esac

echo "Step 10: Verifying removal..."
if command -v podman >/dev/null 2>&1; then
    echo "⚠️  podman still present at: $(command -v podman)"
else
    echo "✅ podman removed"
fi

if command -v podman-compose >/dev/null 2>&1; then
    echo "⚠️  podman-compose still present at: $(command -v podman-compose)"
else
    echo "✅ podman-compose removed"
fi

if command -v ipc >/dev/null 2>&1; then
    echo "⚠️  ipc still present at: $(command -v ipc)"
else
    echo "✅ ipc removed"
fi

echo ""
echo "💡 Restart your terminal or run: source ~/.bashrc (or source ~/.zshrc)"
echo "   to unload the dipen function from your current shell session."
echo ""

echo "=========================================="
echo "Podman uninstallation completed!"
echo "=========================================="