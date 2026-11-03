#!/bin/bash

set -o pipefail

echo "=========================================="
echo "Starting Podman installation"
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

install_pkgs() {
    case "$PKG_MGR" in
        apt) sudo apt install -y "$@" ;;
        dnf) sudo dnf install -y "$@" ;;
        yum) sudo yum install -y "$@" ;;
    esac
}

update_system() {
    case "$PKG_MGR" in
        apt) sudo apt update && sudo apt upgrade -y ;;
        dnf) sudo dnf upgrade -y ;;
        yum) sudo yum update -y ;;
    esac
}

echo "Step 1: Updating and upgrading system..."
update_system

echo "Step 2: Installing Podman..."
install_pkgs podman

echo "Step 3: Installing supporting packages..."
case "$DISTRO_FAMILY" in
    debian)
        install_pkgs uidmap slirp4netns dbus-user-session fuse-overlayfs
        ;;
    rhel)
        install_pkgs fuse-overlayfs slirp4netns shadow-utils
        ;;
esac

echo "Ensuring python3 and venv are available..."
case "$PKG_MGR" in
    apt) install_pkgs python3 python3-venv python3-pip ;;
    dnf|yum) install_pkgs python3 python3-pip ;;
esac

echo "Step 4: Enabling linger for user $USER..."
sudo loginctl enable-linger $USER

echo "Step 5: Checking linger status..."
loginctl show-user $USER | grep Linger

echo "Step 6: Installing podman-compose via Python venv..."
VENV_DIR="$HOME/.local/share/podman-compose-venv"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install podman-compose
deactivate
sudo ln -sf "$VENV_DIR/bin/podman-compose" /usr/local/bin/podman-compose
echo "✅ podman-compose installed at /usr/local/bin/podman-compose"

echo "Step 7: Checking podman-compose version..."
podman-compose --version

echo "Step 8: Running hello-world test..."
podman run hello-world

echo "Step 9: Editing registry configuration..."
echo "Opening /etc/containers/registries.conf with nano"
echo "Add the following line:"
echo "unqualified-search-registries = [\"docker.io\", \"ghcr.io\", \"dock.mau.dev\"]"
echo ""
sudo nano /etc/containers/registries.conf

echo "Step 10: Enabling podman.socket..."
systemctl --user enable --now podman.socket

echo "Step 11: Setting up dipen wrapper function..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIPEN_PATH="${SCRIPT_DIR}/dipen.sh"
IPC_PATH="${SCRIPT_DIR}/ipc"

MARKER_BEGIN="# >>> dipen wrapper >>>"
MARKER_END="# <<< dipen wrapper <<<"

write_dipen_block() {
    cat << EOF
${MARKER_BEGIN}
dipen() {
    local script="${DIPEN_PATH}"
    case "\$1" in
        cd)
            shift
            if [[ "\$1" == "volume" ]]; then
                shift
                local vol_dir="\$HOME/.local/share/containers/storage/volumes"
                if [[ -d "\$vol_dir" ]]; then
                    builtin cd "\$vol_dir"
                    echo "📁 \$vol_dir"
                    echo
                    if [[ -n "\$1" ]]; then
                        ls -lh | grep -i "\$1"
                    else
                        ls -lh
                    fi
                else
                    echo "Error: Volume directory not found: \$vol_dir"
                    return 1
                fi
            else
                local target
                target=\$("\$script" cd "\$@" 2>/dev/null | grep -oP '(?<=^\\s{2}cd ).*' | head -1)
                if [[ -n "\$target" && -d "\$target" ]]; then
                    builtin cd "\$target"
                else
                    "\$script" cd "\$@"
                fi
            fi
            ;;
        *)
            "\$script" "\$@"
            ;;
    esac
}
${MARKER_END}
EOF
}

update_shell_rc() {
    local shell_rc="$1"
    local shell_name="$2"

    if [ ! -f "$shell_rc" ]; then
        echo "ℹ️  $shell_rc not found, skipping $shell_name"
        return 0
    fi

    cp "$shell_rc" "${shell_rc}.bak.$(date +%Y%m%d_%H%M%S)"
    echo "📦 Backed up $shell_rc"

    if grep -qE "^\s*alias\s+dipen=" "$shell_rc" 2>/dev/null; then
        sed -i.bak -E "/^\s*alias\s+dipen=/d" "$shell_rc"
        echo "🗑️  Removed old 'alias dipen=' from $shell_rc"
    fi

    if grep -qE "^# Digital Independence - dipen$" "$shell_rc" 2>/dev/null; then
        sed -i.bak -E "/^# Digital Independence - dipen$/d" "$shell_rc"
        echo "🗑️  Removed old comment from $shell_rc"
    fi

    if grep -qF "$MARKER_BEGIN" "$shell_rc" 2>/dev/null; then
        sed -i.bak "/^${MARKER_BEGIN}$/,/^${MARKER_END}$/d" "$shell_rc"
        echo "🗑️  Removed old dipen wrapper block from $shell_rc"
    fi

    rm -f "${shell_rc}.bak" 2>/dev/null

    echo "" >> "$shell_rc"
    write_dipen_block >> "$shell_rc"
    echo "✅ Added dipen wrapper to $shell_rc"
}

if [ -f "$DIPEN_PATH" ]; then
    chmod +x "$DIPEN_PATH" 2>/dev/null || true
    if [ -f ~/.bashrc ]; then
        update_shell_rc ~/.bashrc "bash"
    fi
    if [ -f ~/.zshrc ]; then
        update_shell_rc ~/.zshrc "zsh"
    fi
else
    echo "⚠️  dipen.sh not found at: $DIPEN_PATH"
    echo "   Skipping dipen wrapper setup"
fi

echo ""
echo "Step 12: Installing ipc (Iptables Controller) to /usr/local/bin..."
if [ -f "$IPC_PATH" ]; then
    read -p "Do you want to install 'ipc' to /usr/local/bin/ipc? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing ipc to /usr/local/bin/ipc..."
        sudo cp "$IPC_PATH" /usr/local/bin/ipc
        sudo chmod 755 /usr/local/bin/ipc
        echo "✅ ipc installed successfully at /usr/local/bin/ipc"
        echo "   Verify with: ipc version"
    else
        echo "⏭️  Skipped ipc installation"
    fi
else
    echo "⚠️  ipc not found at: $IPC_PATH"
    echo "   Skipping ipc installation"
fi

echo ""
echo "💡 To use the dipen wrapper, either:"
echo "   - Restart your terminal, or"
echo "   - Run: source ~/.bashrc (or source ~/.zshrc)"
echo ""
echo "📝 Examples after setup:"
echo "   dipen list"
echo "   dipen up portainer"
echo "   dipen env nextcloud"
echo "   dipen cd nextcloud"
echo "   dipen cd volume"
echo "   dipen cd volume nextcloud"
echo ""

echo "=========================================="
echo "Podman installation completed successfully!"
echo "=========================================="