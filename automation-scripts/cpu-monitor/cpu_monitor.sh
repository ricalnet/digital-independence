#!/bin/bash

set -euo pipefail

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Monitor CPU usage and send alert via ntfy if threshold exceeded.

Options:
  -c, --config FILE   Path to configuration file (default: ./cpu_monitor.conf or /etc/cpu_monitor.conf)
  -l, --log FILE      Path to log file (overrides LOG_FILE in config)
  -h, --help          Show this help message
EOF
    exit 0
}

CONFIG_FILE=""
LOG_FILE_OVERRIDE=""

if [[ -f "./cpu_monitor.conf" ]]; then
    CONFIG_FILE="./cpu_monitor.conf"
elif [[ -f "/etc/cpu_monitor.conf" ]]; then
    CONFIG_FILE="/etc/cpu_monitor.conf"
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE_OVERRIDE="$2"
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
    echo "Error: Configuration file not found. Please specify with -c or place cpu_monitor.conf in current directory or /etc/"
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file '$CONFIG_FILE' does not exist."
    exit 1
fi

source "$CONFIG_FILE"

THRESHOLD="${THRESHOLD:-80}"
INTERVAL="${INTERVAL:-60}"
NTFY_TOPIC="${NTFY_TOPIC:-}"
NTFY_TOKEN="${NTFY_TOKEN:-}"
NTFY_URL="${NTFY_URL:-https://ntfy.sh}"
LOG_FILE="${LOG_FILE:-./cpu_monitor.log}"

if [[ -n "$LOG_FILE_OVERRIDE" ]]; then
    LOG_FILE="$LOG_FILE_OVERRIDE"
fi

if [[ -z "$NTFY_TOPIC" || -z "$NTFY_TOKEN" ]]; then
    echo "Error: NTFY_TOPIC and NTFY_TOKEN must be set in configuration."
    exit 1
fi

LOG_DIR=$(dirname "$LOG_FILE")
if [[ ! -d "$LOG_DIR" ]]; then
    mkdir -p "$LOG_DIR" 2>/dev/null || {
        echo "Error: Cannot create log directory '$LOG_DIR'"
        exit 1
    }
fi

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$message" | while IFS= read -r line; do
        echo "[$timestamp] $line" | tee -a "$LOG_FILE"
    done
}

get_cpu_usage() {
    local cpu1=$(cat /proc/stat | grep '^cpu ' | head -1)
    sleep 1
    local cpu2=$(cat /proc/stat | grep '^cpu ' | head -1)

    echo "$cpu1" "$cpu2" | awk '
    {
        # First line: cpu1
        if (NR==1) {
            user1=$2; nice1=$3; sys1=$4; idle1=$5; iowait1=$6; irq1=$7; softirq1=$8; steal1=$9; guest1=$10; guest_nice1=$11
        }
        # Second line: cpu2
        if (NR==2) {
            user2=$2; nice2=$3; sys2=$4; idle2=$5; iowait2=$6; irq2=$7; softirq2=$8; steal2=$9; guest2=$10; guest_nice2=$11
        }
    }
    END {
        total1 = user1 + nice1 + sys1 + idle1 + iowait1 + irq1 + softirq1 + steal1 + guest1 + guest_nice1
        total2 = user2 + nice2 + sys2 + idle2 + iowait2 + irq2 + softirq2 + steal2 + guest2 + guest_nice2
        idle_total1 = idle1 + iowait1
        idle_total2 = idle2 + iowait2
        delta_total = total2 - total1
        delta_idle = idle_total2 - idle_total1
        if (delta_total == 0) {
            printf "0.00"
        } else {
            printf "%.2f", 100 * (delta_total - delta_idle) / delta_total
        }
    }'
}

send_notification() {
    local cpu_usage="$1"
    local hostname=$(hostname 2>/dev/null || echo "unknown")
    local message="⚠️ CPU usage on $hostname is ${cpu_usage}% (threshold: ${THRESHOLD}%)"

    curl -s -X POST \
        -H "Authorization: Bearer $NTFY_TOKEN" \
        -H "Title: CPU Alert" \
        -H "Priority: high" \
        -H "Tags: warning" \
        -d "$message" \
        "$NTFY_URL/$NTFY_TOPIC" > /dev/null 2>&1

    if [[ $? -eq 0 ]]; then
        log_message "NOTIFICATION SENT: $message"
    else
        log_message "ERROR: Failed to send notification."
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

trap 'log_message "CPU monitor stopped."; exit 0' INT TERM

log_message "CPU Monitor started. Threshold: ${THRESHOLD}%, Interval: ${INTERVAL}s, Log: ${LOG_FILE}"

while true; do
    cpu=$(get_cpu_usage)
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    is_exceeded=$(echo "$cpu $THRESHOLD" | awk '{print ($1 > $2) ? 1 : 0}')

    if [[ "$is_exceeded" -eq 1 ]]; then
        status="WARNING"
        color=$RED
        send_notification "$cpu"
    else
        status="OK"
        color=$GREEN
    fi

    log_message "CPU Usage: ${cpu}% (Status: ${status})"

    sleep "$INTERVAL"
done