#!/bin/bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Monitor memory usage and send alert via ntfy if threshold exceeded.

Options:
  -c, --config FILE   Path to configuration file (default: ./memory_monitor.conf or /etc/memory_monitor.conf)
  -h, --help          Show this help message
EOF
    exit 0
}

CONFIG_FILE=""
if [[ -f "./memory_monitor.conf" ]]; then
    CONFIG_FILE="./memory_monitor.conf"
elif [[ -f "/etc/memory_monitor.conf" ]]; then
    CONFIG_FILE="/etc/memory_monitor.conf"
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [[ -z "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found. Please specify with -c or place memory_monitor.conf in current directory or /etc/"
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file '$CONFIG_FILE' does not exist."
    exit 1
fi

source "$CONFIG_FILE"

THRESHOLD="${THRESHOLD:-90}"
INTERVAL="${INTERVAL:-60}"
NTFY_TOPIC="${NTFY_TOPIC:-}"
NTFY_TOKEN="${NTFY_TOKEN:-}"
NTFY_URL="${NTFY_URL:-https://ntfy.sh}"

if [[ -z "$NTFY_TOPIC" || -z "$NTFY_TOKEN" ]]; then
    echo "Error: NTFY_TOPIC and NTFY_TOKEN must be set in configuration."
    exit 1
fi

get_memory_usage() {
    local meminfo=$(cat /proc/meminfo)
    
    echo "$meminfo" | awk '
    /^MemTotal:/ { total = $2 }
    /^MemAvailable:/ { available = $2 }
    /^MemFree:/ { free = $2 }
    /^Buffers:/ { buffers = $2 }
    /^Cached:/ { cached = $2 }
    /^SReclaimable:/ { sreclaimable = $2 }
    END {
        # If MemAvailable is available (kernel >= 3.14), use that
        if (available > 0) {
            used = total - available
        } else {
            # Fallback: used = total - free - buffers - cached - sreclaimable
            used = total - free - buffers - cached - sreclaimable
        }
        if (total == 0) {
            printf "0.00"
        } else {
            printf "%.2f", (used / total) * 100
        }
    }'
}

send_notification() {
    local mem_usage="$1"
    local hostname=$(hostname 2>/dev/null || echo "unknown")
    local message="⚠️ Memory usage on $hostname is ${mem_usage}% (threshold: ${THRESHOLD}%)"

    curl -s -X POST \
        -H "Authorization: Bearer $NTFY_TOKEN" \
        -H "Title: Memory Alert" \
        -H "Priority: high" \
        -H "Tags: warning" \
        -d "$message" \
        "$NTFY_URL/$NTFY_TOPIC" > /dev/null 2>&1

    if [[ $? -eq 0 ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] NOTIFICATION SENT: $message"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to send notification."
    fi
}

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; NC=''
fi

trap 'echo -e "\n[$(date)] Exiting memory monitor."; exit 0' INT TERM

echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] Memory Monitor started. Threshold: ${THRESHOLD}%, Interval: ${INTERVAL}s${NC}"

while true; do
    mem=$(get_memory_usage)
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    is_exceeded=$(echo "$mem $THRESHOLD" | awk '{print ($1 > $2) ? 1 : 0}')

    if [[ "$is_exceeded" -eq 1 ]]; then
        status="WARNING"
        color=$RED
        send_notification "$mem"
    else
        status="OK"
        color=$GREEN
    fi

    echo -e "[$timestamp] Memory Usage: ${color}${mem}%${NC} (Status: ${color}${status}${NC})"

    sleep "$INTERVAL"
done