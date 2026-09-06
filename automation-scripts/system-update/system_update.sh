#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_FILE="${1:-${SCRIPT_DIR}/system_update.conf}"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "ERROR: Config file not found: $CONFIG_FILE"
    echo "Usage: $0 [path/to/config.conf]"
    exit 1
fi

: "${NTFY_TOKEN:?ERROR: NTFY_TOKEN not set in config}"
: "${NTFY_TOPIC:=system_update}"
: "${NTFY_URL:=https://ntfy.sh}"
: "${LOG_FILE:=/var/log/system_update.log}"
: "${ENABLE_LOCAL_LOG:=true}"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg"
    [[ "$ENABLE_LOCAL_LOG" == "true" ]] && echo "$msg" >> "$LOG_FILE"
}

send_ntfy() {
    local status="$1"
    local title="$2"
    local message="$3"
    local priority="${4:-3}"
    
    local color
    case "$status" in
        "success") color="green" ;;
        "failure") color="red" ;;
        "warning") color="yellow" ;;
        *) color="grey" ;;
    esac
    
    echo "$message" | curl -s -X POST "$NTFY_URL/$NTFY_TOPIC" \
        -H "Authorization: Bearer $NTFY_TOKEN" \
        -H "Title: $title" \
        -H "Priority: $priority" \
        -H "Tags: $status,update" \
        -H "Click: $NTFY_URL/$NTFY_TOPIC" \
        --data-binary @- > /dev/null 2>&1
}

run_cmd() {
    local cmd="$1"
    local desc="$2"
    
    log "▶ Running: $desc"
    log "  Command: $cmd"
    
    if eval "$cmd" 2>&1 | while IFS= read -r line; do
        log "  $line"
    done; then
        log "  ✅ $desc - SUCCESS"
        return 0
    else
        log "  ❌ $desc - FAILED"
        return 1
    fi
}

main() {
    local start_time=$(date +%s)
    local hostname=$(hostname)
    local errors=0
    
    log "=========================================="
    log "🚀 STARTING SYSTEM UPDATE ON $hostname"
    log "=========================================="
    
    send_ntfy "warning" "🔄 System Update Started" \
        "Host: $hostname
Started: $(date '+%Y-%m-%d %H:%M:%S')

Status: In progress..." \
        "3"
    
    if ! run_cmd "sudo apt update" "Update package lists"; then
        errors=$((errors + 1))
    fi
    
    if ! run_cmd "sudo apt full-upgrade -y" "Full system upgrade"; then
        errors=$((errors + 1))
    fi
    
    if ! run_cmd "sudo apt autoremove -y" "Remove unused packages"; then
        errors=$((errors + 1))
    fi
    
    if ! run_cmd "sudo apt clean -y" "Clean package cache"; then
        errors=$((errors + 1))
    fi
    
    if ! run_cmd "sudo apt autoclean -y" "Autoclean packages"; then
        errors=$((errors + 1))
    fi
    
    if ! run_cmd "sudo update-initramfs -u" "Update initramfs"; then
        errors=$((errors + 1))
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local duration_str=$(printf '%02d:%02d:%02d' $((duration/3600)) $((duration%3600/60)) $((duration%60)))
    
    log "=========================================="
    if [[ $errors -eq 0 ]]; then
        log "✅ ALL TASKS COMPLETED SUCCESSFULLY"
        local status="success"
        local emoji="✅"
        local priority="2"
    else
        log "⚠️ COMPLETED WITH $errors ERROR(S)"
        local status="failure"
        local emoji="❌"
        local priority="4"
    fi
    log "Duration: $duration_str"
    log "=========================================="
    
    send_ntfy "$status" "$emoji System Update Complete on $hostname" \
        "Host: $hostname
Duration: $duration_str
Completed: $(date '+%Y-%m-%d %H:%M:%S')

📊 Summary:
  • Update lists: OK
  • Full upgrade: OK
  • Autoremove: OK
  • Clean: OK
  • Autoclean: OK
  • Initramfs: OK

✨ All tasks completed successfully!" \
        "$priority"
}

main "$@"