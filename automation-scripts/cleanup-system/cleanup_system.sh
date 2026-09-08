#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_FILE="${1:-$SCRIPT_DIR/cleanup_system.conf}"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "ERROR: Config file not found: $CONFIG_FILE"
    echo "Usage: $0 [path/to/config.conf]"
    echo "Default: $SCRIPT_DIR/cleanup_system.conf"
    exit 1
fi

: "${NTFY_TOKEN:?ERROR: NTFY_TOKEN not set in config}"
: "${NTFY_TOPIC:=system-cleanup}"
: "${NTFY_URL:=https://ntfy.sh}"
: "${LOG_FILE:=$SCRIPT_DIR/cleanup_system.log}"
: "${ENABLE_LOCAL_LOG:=true}"
: "${USERNAME:=ricalnet}"
: "${CUSTOM_DIRS:=}"

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
    
    echo "$message" | curl -s -X POST "$NTFY_URL/$NTFY_TOPIC" \
        -H "Authorization: Bearer $NTFY_TOKEN" \
        -H "Title: $title" \
        -H "Priority: $priority" \
        -H "Tags: $status,cleanup" \
        -H "Click: $NTFY_URL/$NTFY_TOPIC" \
        --data-binary @- > /dev/null 2>&1
}

run_cmd() {
    local cmd="$1"
    local desc="$2"
    local continue_on_error="${3:-false}"
    
    log "▶ Running: $desc"
    log "  Command: $cmd"
    
    if eval "$cmd" 2>&1 | while IFS= read -r line; do
        log "  $line"
    done; then
        log "  ✅ $desc - SUCCESS"
        return 0
    else
        log "  ❌ $desc - FAILED"
        if [[ "$continue_on_error" == "true" ]]; then
            log "  ⚠️ Continuing despite error..."
            return 0
        else
            return 1
        fi
    fi
}

get_disk_usage() {
    local path="$1"
    if [[ -d "$path" ]]; then
        du -sh "$path" 2>/dev/null | awk '{print $1}'
    else
        echo "N/A"
    fi
}

delete_custom_dirs() {
    local dirs="$1"
    local total_size=0
    local deleted_count=0
    local summary=""
    
    log "▶ Cleaning custom directories"
    
    for dir in $dirs; do
        if [[ -d "$dir" ]]; then
            local size=$(get_disk_usage "$dir")
            log "  Found: $dir (Size: $size)"
            
            if rm -rf "$dir"/* 2>/dev/null || rm -rf "$dir" 2>/dev/null; then
                log "  ✅ Deleted: $dir"
                deleted_count=$((deleted_count + 1))
                summary="$summary
    • $dir ($size) - Deleted ✓"
            else
                log "  ❌ Failed to delete: $dir (permission denied or not empty)"
                summary="$summary
    • $dir - Failed ✗"
            fi
        else
            log "  ⚠️ Directory not found: $dir"
            summary="$summary
    • $dir - Not found ⚠️"
        fi
    done
    
    echo "$summary"
    return 0
}

main() {
    local start_time=$(date +%s)
    local hostname=$(hostname)
    local errors=0
    local custom_summary=""
    
    log "=========================================="
    log "🧹 STARTING SYSTEM CLEANUP ON $hostname"
    log "=========================================="
    
    log "📊 Disk usage before cleanup:"
    df -h / | while read -r line; do
        log "  $line"
    done
    
    send_ntfy "warning" "🧹 System Cleanup Started" \
        "Host: $hostname
Started: $(date '+%Y-%m-%d %H:%M:%S')
User: $USERNAME

Status: In progress..." \
        "3"
    
    if ! run_cmd "sudo apt clean" "Clean APT package cache"; then
        errors=$((errors + 1))
    fi
    
    if ! run_cmd "sudo apt autoremove -y" "Remove unused packages"; then
        errors=$((errors + 1))
    fi
    
    log "▶ Running: Remove residual config packages"
    log "  Command: dpkg -l | grep '^rc' | awk '{print \$2}' | sudo xargs dpkg --purge"
    
    local residual_packages=$(dpkg -l | grep '^rc' | awk '{print $2}' || true)
    if [[ -n "$residual_packages" ]]; then
        log "  Found residual packages: $residual_packages"
        if echo "$residual_packages" | sudo xargs dpkg --purge 2>&1 | while IFS= read -r line; do
            log "  $line"
        done; then
            log "  ✅ Remove residual config packages - SUCCESS"
        else
            log "  ❌ Remove residual config packages - FAILED"
            errors=$((errors + 1))
        fi
    else
        log "  No residual config packages found"
        log "  ✅ Remove residual config packages - SKIPPED (none found)"
    fi
    
    log "▶ Checking log directory size"
    local log_size=$(get_disk_usage "/var/log")
    log "  Current /var/log size: $log_size"
    
    if ! run_cmd "sudo rm -vf /var/log/*.gz /var/log/*.1 /var/log/*.old" "Remove old log files" "true"; then
        log "  ⚠️ No old log files found or permission denied"
    fi
    
    if ! run_cmd "sudo journalctl --vacuum-time=2d" "Clean journald (older than 2 days)"; then
        errors=$((errors + 1))
    fi
    
    if ! run_cmd "sudo journalctl --vacuum-size=50M" "Clean journald (max 50MB)"; then
        errors=$((errors + 1))
    fi
    
    local thumb_dir="/home/$USERNAME/.cache/thumbnails"
    if [[ -d "$thumb_dir" ]]; then
        local thumb_size=$(get_disk_usage "$thumb_dir")
        log "▶ Cleaning thumbnails directory"
        log "  Current size: $thumb_size"
        if ! run_cmd "rm -rf $thumb_dir/*" "Clean thumbnails cache" "true"; then
            log "  ⚠️ Could not clean thumbnails (maybe empty or permission denied)"
        fi
    else
        log "⚠️ Thumbnails directory not found: $thumb_dir"
    fi
    
    local trash_dir="/home/$USERNAME/.local/share/Trash"
    if [[ -d "$trash_dir" ]]; then
        local trash_size=$(get_disk_usage "$trash_dir")
        log "▶ Cleaning trash directory"
        log "  Current size: $trash_size"
        if ! run_cmd "rm -rf $trash_dir/*" "Clean trash" "true"; then
            log "  ⚠️ Could not clean trash (maybe empty or permission denied)"
        fi
    else
        log "⚠️ Trash directory not found: $trash_dir"
    fi
    
    if [[ -n "$CUSTOM_DIRS" ]]; then
        log "▶ Processing custom directories"
        custom_summary=$(delete_custom_dirs "$CUSTOM_DIRS")
        log "$custom_summary"
    else
        log "ℹ️ No custom directories configured (CUSTOM_DIRS is empty)"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local duration_str=$(printf '%02d:%02d:%02d' $((duration/3600)) $((duration%3600/60)) $((duration%60)))
    
    log "📊 Disk usage after cleanup:"
    df -h / | while read -r line; do
        log "  $line"
    done
    
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
    
    local summary_msg="Host: $hostname
Duration: $duration_str
Completed: $(date '+%Y-%m-%d %H:%M:%S')
User: $USERNAME

📊 Cleanup Summary:
  • APT cache: Cleaned ✓
  • Unused packages: Removed ✓
  • Residual configs: Purged ✓
  • Old logs: Removed ✓
  • Journald: Cleaned ✓
  • Thumbnails: Cleaned ✓
  • Trash: Emptied ✓"

    if [[ -n "$CUSTOM_DIRS" && -n "$custom_summary" ]]; then
        summary_msg="$summary_msg
  • Custom directories:$custom_summary"
    elif [[ -n "$CUSTOM_DIRS" ]]; then
        summary_msg="$summary_msg
  • Custom directories: No directories found"
    else
        summary_msg="$summary_msg
  • Custom directories: None configured"
    fi

    summary_msg="$summary_msg

Disk usage after cleanup:
$(df -h / | tail -n1)

$([[ $errors -eq 0 ]] && echo "✨ All tasks completed successfully!" || echo "⚠️ $errors task(s) failed. Check logs for details.")"

    send_ntfy "$status" "$emoji System Cleanup Complete on $hostname" "$summary_msg" "$priority"
}

main "$@"