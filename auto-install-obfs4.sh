#!/bin/bash
# auto-install-obfs4.sh

set -e
set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

CONTAINER_NAME="obfs4-bridge"
NETWORK_NAME="obfs4_bridge_external_network"

log_info "Checking required files and dependencies..."

for f in ipc install-podman-on-debian.sh; do
    if [[ ! -f "$f" ]]; then
        log_error "File '$f' not found in $(pwd)."
        exit 1
    fi
done

if [[ ! -d obfs4-bridge ]]; then
    log_error "Directory 'obfs4-bridge' not found in $(pwd)."
    exit 1
fi

for cmd in sudo apt podman curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "Command '$cmd' is not available."
        exit 1
    fi
done

log_success "All required files and base dependencies are available."

log_info "Installing ipc binary..."
sudo install -m 0755 ipc /usr/local/bin/ipc
log_success "ipc installed to /usr/local/bin/ipc"

log_info "Installing iptables and iptables-persistent..."
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y iptables iptables-persistent

log_info "Setting up persistence..."
sudo ipc setup-persistence

log_info "Initializing ipc..."
sudo ipc init

log_info "Enabling port 8443 (both tcp)..."
sudo ipc enable 8443 both tcp

log_info "Enabling port 9443 (both tcp)..."
sudo ipc enable 9443 both tcp

log_info "ipc status:"
sudo ipc status

log_info "Installing Podman..."
chmod +x install-podman-on-debian.sh
./install-podman-on-debian.sh

if ! command -v podman-compose >/dev/null 2>&1; then
    log_error "podman-compose is not installed."
    exit 1
fi
log_success "Podman & podman-compose are ready."

log_info "Entering obfs4-bridge directory..."
cd obfs4-bridge

log_info "Creating .env from .env.example..."
cp .env.example .env

echo ""
echo -e "${YELLOW}=== obfs4 bridge configuration ===${NC}"
echo ""

while true; do
    read -rp "EMAIL (example: name@email.com): " EMAIL_INPUT
    [[ -z "$EMAIL_INPUT" ]] && { log_error "EMAIL cannot be empty!"; continue; }
    if [[ ! "$EMAIL_INPUT" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        log_warn "EMAIL format looks invalid. Continue anyway? (y/n)"
        read -rp "> " KONFIRMASI
        [[ "$KONFIRMASI" =~ ^[Yy]$ ]] && break
        continue
    fi
    break
done

while true; do
    read -rp "NICKNAME (bridge name, no spaces): " NICKNAME_INPUT
    [[ -z "$NICKNAME_INPUT" ]] && { log_error "NICKNAME cannot be empty!"; continue; }
    [[ "$NICKNAME_INPUT" =~ [[:space:]] ]] && { log_error "NICKNAME cannot contain spaces!"; continue; }
    break
done

echo ""
log_info "EMAIL    : $EMAIL_INPUT"
log_info "NICKNAME : $NICKNAME_INPUT"
echo ""

escape_sed() { printf '%s\n' "$1" | sed -e 's/[\/&]/\\&/g'; }
EMAIL_ESC=$(escape_sed "$EMAIL_INPUT")
NICKNAME_ESC=$(escape_sed "$NICKNAME_INPUT")

if grep -qE '^[[:space:]]*EMAIL=' .env; then
    sed -i "s/^[[:space:]]*EMAIL=.*/EMAIL=${EMAIL_ESC}/" .env
else
    echo "EMAIL=${EMAIL_INPUT}" >> .env
fi

if grep -qE '^[[:space:]]*NICKNAME=' .env; then
    sed -i "s/^[[:space:]]*NICKNAME=.*/NICKNAME=${NICKNAME_ESC}/" .env
else
    echo "NICKNAME=${NICKNAME_INPUT}" >> .env
fi

if grep -qE '^[[:space:]]*OR_PORT=' .env; then
    sed -i "s/^[[:space:]]*OR_PORT=.*/OR_PORT=8443/" .env
else
    echo "OR_PORT=8443" >> .env
fi

if grep -qE '^[[:space:]]*PT_PORT=' .env; then
    sed -i "s/^[[:space:]]*PT_PORT=.*/PT_PORT=9443/" .env
else
    echo "PT_PORT=9443" >> .env
fi

log_success ".env configured successfully."
echo ""
echo -e "${YELLOW}--- .env contents ---${NC}"
cat .env
echo ""
echo -e "${YELLOW}----------------${NC}"
echo ""

OR_PORT=$(grep -E '^[[:space:]]*OR_PORT=' .env | head -1 | cut -d= -f2 | tr -d '[:space:]')
PT_PORT=$(grep -E '^[[:space:]]*PT_PORT=' .env | head -1 | cut -d= -f2 | tr -d '[:space:]')
OR_PORT=${OR_PORT:-8443}
PT_PORT=${PT_PORT:-9443}
log_info "OR_PORT=$OR_PORT  PT_PORT=$PT_PORT"

log_info "Checking network '${NETWORK_NAME}'..."
if podman network exists "${NETWORK_NAME}" 2>/dev/null; then
    log_success "Network '${NETWORK_NAME}' already exists."
else
    log_warn "Network '${NETWORK_NAME}' not found. Creating..."
    if ! podman network create "${NETWORK_NAME}"; then
        log_error "Failed to create network '${NETWORK_NAME}'."
        exit 1
    fi
    log_success "Network '${NETWORK_NAME}' created successfully."
fi

if podman container exists "${CONTAINER_NAME}" 2>/dev/null; then
    OLD_STATUS=$(podman ps -a --filter "name=^${CONTAINER_NAME}$" --format '{{.Status}}' | head -1)
    if [[ "$OLD_STATUS" != Up* ]]; then
        log_warn "Old container '${CONTAINER_NAME}' (${OLD_STATUS}) removed."
        podman rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    fi
fi

log_info "Running podman-compose up -d..."
podman-compose up -d

log_info "Container status:"
podman-compose ps || true

log_info "Waiting for container '${CONTAINER_NAME}' to run..."
READY=0
FAILED=0
for i in {1..60}; do
    STATUS=$(podman ps -a --filter "name=^${CONTAINER_NAME}$" --format '{{.Status}}' 2>/dev/null | head -1 || true)
    if [[ "$STATUS" == Up* ]]; then
        READY=1
        break
    fi
    if [[ $i -ge 5 && ( "$STATUS" == Created* || "$STATUS" == Exited* ) ]]; then
        FAILED=1
        break
    fi
    sleep 2
done

if [[ $READY -eq 1 ]]; then
    log_success "Container '${CONTAINER_NAME}' is running."
elif [[ $FAILED -eq 1 ]]; then
    log_error "Container '${CONTAINER_NAME}' failed to start (status: ${STATUS})."
    podman logs "${CONTAINER_NAME}" 2>&1 | tail -30 || true
    exit 1
else
    log_warn "Container not detected after 120 seconds."
fi

log_info "Showing last 50 log lines:"
podman-compose logs --tail=50 || true

log_info "=== Checking container status ==="
podman ps --filter "name=^${CONTAINER_NAME}$" \
          --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true

log_info "=== Waiting 3 minutes for bootstrap ==="
for i in {1..18}; do
    printf "\rWaiting for bootstrap... %ds" $((i*10))
    sleep 10
done
echo ""

log_info "=== Checking bootstrap logs ==="
podman logs "${CONTAINER_NAME}" 2>/dev/null | grep -i bootstrap || echo "No bootstrap logs found"

log_info "=== Extracting fingerprint ==="
FINGERPRINT=$(podman exec "${CONTAINER_NAME}" cat /var/lib/tor/fingerprint 2>/dev/null \
              | cut -d' ' -f2 | tr -d '[:space:]' || true)

VERIFY_OK=1
if [[ ! "$FINGERPRINT" =~ ^[A-F0-9]{40}$ ]]; then
    log_warn "Fingerprint not yet valid: '${FINGERPRINT:-<empty>}'"
    VERIFY_OK=0
fi

log_info "=== Reading bridge line ==="
RAW_FILE=$(podman exec "${CONTAINER_NAME}" cat /var/lib/tor/pt_state/obfs4_bridgeline.txt 2>/dev/null || true)
BRIDGE_TEMPLATE=$(echo "$RAW_FILE" | grep -E '^Bridge obfs4 ' | head -1 || true)

if [[ -z "$BRIDGE_TEMPLATE" ]]; then
    log_warn "Bridge line not available in obfs4_bridgeline.txt."
    VERIFY_OK=0
fi

CERT=""
IAT_MODE=""
if [[ $VERIFY_OK -eq 1 ]]; then
    CERT=$(echo "$BRIDGE_TEMPLATE" | grep -oE 'cert=[^ ]+' || true)
    IAT_MODE=$(echo "$BRIDGE_TEMPLATE" | grep -oE 'iat-mode=[0-9]+' || true)

    if [[ -z "$CERT" ]]; then
        log_warn "cert= not found in bridge line."
        VERIFY_OK=0
    fi
fi

PUBLIC_IP="IP_NOT_FOUND"
if command -v curl >/dev/null 2>&1; then
    PUBLIC_IP=$(curl -s --max-time 10 ifconfig.me \
                || curl -s --max-time 10 icanhazip.com \
                || echo "IP_NOT_FOUND")
fi

if [[ "$PUBLIC_IP" == "IP_NOT_FOUND" ]]; then
    log_warn "Could not retrieve public IP."
    VERIFY_OK=0
fi

FINAL_BRIDGE_LINE=""
if [[ $VERIFY_OK -eq 1 ]]; then
    FINAL_BRIDGE_LINE=$(echo "$BRIDGE_TEMPLATE" \
        | sed -e "s|<IP ADDRESS>|${PUBLIC_IP}|g" \
              -e "s|<PORT>|${PT_PORT}|g" \
              -e "s|<FINGERPRINT>|${FINGERPRINT}|g" \
        | sed -e 's/^Bridge obfs4 //')

    if [[ "$FINAL_BRIDGE_LINE" == *"<"* ]] || [[ "$FINAL_BRIDGE_LINE" == *">"* ]]; then
        log_warn "Substitution failed, placeholder still present:"
        echo "  $FINAL_BRIDGE_LINE"
        VERIFY_OK=0
    fi
fi

if [[ $VERIFY_OK -eq 1 ]]; then
    echo ""
    echo "=== Bridge Line for Tor Browser Users: ==="
    echo ""
    echo "obfs4 ${FINAL_BRIDGE_LINE}"
    echo ""
    echo "=== Usage Instructions: ==="
    echo "1. Copy the line above"
    echo "2. Open Tor Browser"
    echo "3. Go to Preferences -> Tor -> Bridges"
    echo "4. Select 'Provide a bridge I know'"
    echo "5. Paste the bridge line"
    echo ""
    echo "=== Detailed Information: ==="
    echo "Fingerprint : ${FINGERPRINT}"
    echo "Port        : ${PT_PORT}"
    echo "Certificate : ${CERT}"
    echo "IAT mode    : ${IAT_MODE:-iat-mode=0}"
    echo "Public IP   : ${PUBLIC_IP}"
else
    log_warn "Verification incomplete. Debug details:"
    echo "  Fingerprint : ${FINGERPRINT:-<empty>}"
    echo "  Raw file    :"
    echo "$RAW_FILE" | sed 's/^/    /'
    echo ""
    log_info "Manual debug commands:"
    echo "  podman exec ${CONTAINER_NAME} cat /var/lib/tor/fingerprint"
    echo "  podman exec ${CONTAINER_NAME} cat /var/lib/tor/pt_state/obfs4_bridgeline.txt"
fi

LOG_DIR="../logs"
LOG_FILE="${LOG_DIR}/obfs4_installation.log"

log_info "Saving installation log to ${LOG_FILE}..."
mkdir -p "${LOG_DIR}"

{
    echo "=================================================="
    echo "Obfs4 Bridge Installation Log"
    echo "Date        : $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Hostname    : $(hostname)"
    echo "Container   : ${CONTAINER_NAME}"
    echo "Network     : ${NETWORK_NAME}"
    echo "OR_PORT     : ${OR_PORT}"
    echo "PT_PORT     : ${PT_PORT}"
    echo "EMAIL       : ${EMAIL_INPUT}"
    echo "NICKNAME    : ${NICKNAME_INPUT}"
    echo "=================================================="
    echo ""
    echo "--- Container Status ---"
    podman ps -a --filter "name=^${CONTAINER_NAME}$" \
        --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true
    echo ""
    echo "--- Bootstrap Log (summary) ---"
    podman logs "${CONTAINER_NAME}" 2>&1 | grep -i bootstrap | tail -20 || true
    echo ""
    echo "--- Fingerprint ---"
    echo "${FINGERPRINT:-<unavailable>}"
    echo ""
    echo "--- Bridge Line (raw file) ---"
    echo "$RAW_FILE"
    echo ""
    if [[ $VERIFY_OK -eq 1 ]]; then
        echo "--- Bridge Line for Tor Browser ---"
        echo "obfs4 ${FINAL_BRIDGE_LINE}"
        echo ""
        echo "--- Details ---"
        echo "Public IP   : ${PUBLIC_IP}"
        echo "Port        : ${PT_PORT}"
        echo "Certificate : ${CERT}"
        echo "IAT mode    : ${IAT_MODE:-iat-mode=0}"
        echo ""
    else
        echo "--- Bridge Line ---"
        echo "<could not be substituted>"
        echo ""
    fi
    echo "=================================================="
    echo "End of log"
    echo "=================================================="
} > "${LOG_FILE}" 2>&1

if [[ -f "${LOG_FILE}" ]]; then
    log_success "Installation log saved: $(realpath "${LOG_FILE}")"
    echo ""
    echo -e "${YELLOW}--- ${LOG_FILE} contents ---${NC}"
    cat "${LOG_FILE}"
    echo -e "${YELLOW}----------------${NC}"
else
    log_warn "Failed to write installation log."
fi

if [[ $VERIFY_OK -eq 1 ]]; then
    log_success "Done! obfs4 bridge installation succeeded & verified."
    echo ""
    log_info "Bridge line for Tor Browser:"
    echo -e "${GREEN}obfs4 ${FINAL_BRIDGE_LINE}${NC}"
else
    log_warn "Installation finished, but verification is incomplete."
    log_warn "Check manually:"
    log_warn "  podman exec ${CONTAINER_NAME} cat /var/lib/tor/pt_state/obfs4_bridgeline.txt"
    log_warn "  podman exec ${CONTAINER_NAME} cat /var/lib/tor/fingerprint"
fi