#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${SCRIPT_DIR}/monthly_recycle.conf"

if [ -f "$CONF_FILE" ]; then
    source "$CONF_FILE"
else
    echo "❌ Config not found: $CONF_FILE"
    echo "📋 Copy template: cp monthly_recycle.conf.example monthly_recycle.conf"
    exit 1
fi

mkdir -p "$LOG_DIR"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
LOG_FILE="${LOG_DIR}/monthly_recycle_${TIMESTAMP}.log"
START_TIME=$(date +%s)
LOCK_FILE="${LOG_DIR}/monthly_recycle.lock"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

format_duration() {
    local s=$1
    printf '%02dh %02dm %02ds' $((s/3600)) $(((s%3600)/60)) $((s%60))
}

get_system_info() {
    echo "🖥️  **Host** : $(hostname)"
    echo "🐧 **OS**   : $(lsb_release -ds 2>/dev/null || echo "Unknown")"
    echo "🔧 **Kernel**: $(uname -r)"
    echo "⏱️  **Uptime**: $(uptime -p | sed 's/up //')"
}

get_resources() {
    echo "💾 **Disk**  : $(df -h / | awk 'NR==2 {print $5 " (" $3 "/" $2 ")"}')"
    echo "🧠 **Memory**: $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
    echo "🐳 **Containers**: $(podman ps -q 2>/dev/null | wc -l) running, $(podman ps -a -q -f status=exited 2>/dev/null | wc -l) stopped"
}

format_service_list() {
    local services="$1"
    local total=$(echo "$services" | wc -w)
    local formatted=""
    local count=0
    
    for service in $services; do
        count=$((count + 1))
        [ $count -le 20 ] && formatted="${formatted}- \`${service}\`\n"
    done
    
    [ $total -gt 20 ] && formatted="${formatted}- ... *and $((total - 20)) more*"
    echo -e "$formatted"
}

send_ntfy() {
    local title="$1"
    local message="$2"
    local priority="${3:-3}"
    
    [ "$ENABLE_NTFY" != "true" ] && return 0
    [ -z "$NTFY_URL" ] || [ -z "$NTFY_TOPIC" ] && return 0
    
    local curl_cmd="curl -X POST -H \"Title: $title\" -H \"Priority: $priority\" -H \"Markdown: yes\""
    [ -n "$NTFY_TOKEN" ] && curl_cmd="$curl_cmd -H \"Authorization: Bearer $NTFY_TOKEN\""
    
    echo "$message" | eval "$curl_cmd --data-binary @- $NTFY_URL/$NTFY_TOPIC" >/dev/null 2>&1 || {
        log "⚠️ Failed to send notification: $title"
    }
}

notify_start() {
    local msg="
# 🔄 **MONTHLY RECYCLE STARTED**

---

## 📊 **Summary**

**⏰ Start** | \`$(date '+%Y-%m-%d %H:%M:%S')\`
**📁 Work Dir** | \`${WORK_DIR}\`
**📦 Services** | **$(echo "$SERVICES" | wc -w)** services
**🎯 Action** | \`recycle\` (pull + down + up)

---

## 🖥️ **System**

$(get_system_info)

---

## 📦 **Services**

$(format_service_list "$SERVICES")

---

## 💾 **Resources**

$(get_resources)

---

## 📝 **Log**

\`${LOG_FILE}\`

---
*⏳ Recycle in progress... Full container refresh*
"

    send_ntfy "🔄 Monthly Recycle Started" "$msg" "4"
}

notify_success() {
    local reboot_msg=""
    [ -f /var/run/reboot-required ] && reboot_msg="\n\n🔁 **Reboot required!** ${AUTO_REBOOT:+Auto-reboot enabled.}" || true
    
    local msg="
# ✅ **MONTHLY RECYCLE COMPLETED**

---

## 📊 **Summary**

**⏱️ Duration** | **$(format_duration $1)**
**📦 Services** | **$(echo "$SERVICES" | wc -w)** recycled
**✅ Status** | **All successful**
**⏰ End** | \`$(date '+%Y-%m-%d %H:%M:%S')\`

---

## 🖥️ **System**

$(get_system_info)

---

## 📦 **Recycled Services**

$(format_service_list "$SERVICES")

---

## 💾 **Resources**

$(get_resources)

---

## 🧹 **Cleanup**

- ✅ dipen.sh recycle completed
- ✅ Old logs cleaned (>${CLEANUP_LOGS_DAYS} days)${reboot_msg}

---

## 📝 **Log**

\`${LOG_FILE}\`

---
*🎉 Monthly recycle completed successfully!*
"

    send_ntfy "✅ Monthly Recycle Completed" "$msg" "4"
}

notify_failure() {
    local exit_code=$1
    local error_log=$(tail -50 "$LOG_FILE" | grep -iE "error|failed|exception" | tail -5 || echo "No errors found")
    
    local msg="
# ❌ **MONTHLY RECYCLE FAILED**

---

## 📊 **Error Summary**

**⏱️ Duration** | **$(format_duration $2)**
**❌ Exit Code** | \`${exit_code}\`
**⏰ Failed** | \`$(date '+%Y-%m-%d %H:%M:%S')\`

---

## 🖥️ **System**

$(get_system_info)

---

## 🔍 **Last Errors**

\`\`\`
${error_log}
\`\`\`

---

## 🔧 **Troubleshooting**

1. **Check full log**:
   \`tail -100 ${LOG_FILE}\`

2. **Manual run**:
   \`cd ${WORK_DIR} && ./dipen.sh recycle ${SERVICES}\`

3. **Check internet**: \`ping -c 4 google.com\`

4. **Check disk**: \`df -h && podman system df\`

---

## 💾 **Resources**

$(get_resources)

---

## 📝 **Log**

\`${LOG_FILE}\`

---
*⚠️ **Please investigate and fix the issue!***
"

    send_ntfy "❌ Monthly Recycle Failed" "$msg" "5"
}

run_apt_update() {
    [ "$RUN_APT_UPDATE" != "true" ] && return 0
    
    log "📦 Running apt update..."
    sudo apt update >> "$LOG_FILE" 2>&1 || log "⚠️ apt update failed (non-fatal)"
    sudo apt full-upgrade -y >> "$LOG_FILE" 2>&1 || log "⚠️ apt upgrade failed (non-fatal)"
    log "✅ apt update completed"
}

run_yourls_frontend() {
    local script="${WORK_DIR}/yourls/frontend.sh"
    [ ! -f "$script" ] && { log "⚠️ YOURLS script not found"; return 1; }
    [ ! -x "$script" ] && chmod +x "$script"
    
    log "▶️ Running YOURLS frontend..."
    bash "$script" >> "$LOG_FILE" 2>&1 && log "✅ YOURLS completed" || log "❌ YOURLS failed"
}

cleanup_old_logs() {
    local deleted=$(find "$LOG_DIR" -name "monthly_recycle_*.log" -mtime +${CLEANUP_LOGS_DAYS} -delete -print 2>/dev/null | wc -l)
    log "✅ Removed $deleted old log files"
}

handle_reboot() {
    if [ -f /var/run/reboot-required ] && [ "${AUTO_REBOOT:-false}" = "true" ]; then
        log "🔁 Reboot required, auto reboot enabled. Rebooting in 30 seconds..."
        send_ntfy "🔁 Reboot Scheduled" "System will reboot in 30 seconds" "4"
        sleep 30
        sudo reboot
    fi
}

if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if kill -0 "$PID" 2>/dev/null; then
        log "❌ Another process running (PID: $PID)"
        send_ntfy "⏭️ Monthly Recycle Skipped" "Another process is running (PID: $PID)" "2"
        exit 1
    fi
    rm -f "$LOCK_FILE"
fi
echo $$ > "$LOCK_FILE"

log "🚀 Starting monthly recycle"
notify_start

cd "$WORK_DIR" || {
    log "❌ Failed to enter $WORK_DIR"
    send_ntfy "❌ Monthly Recycle Failed" "Failed to enter directory $WORK_DIR" "5"
    rm -f "$LOCK_FILE"
    exit 1
}

run_apt_update

log "▶️ Running: ./dipen.sh recycle $SERVICES"
set +e
./dipen.sh recycle $SERVICES >> "$LOG_FILE" 2>&1
EXIT_CODE=$?
set -e

if [ "${RUN_YOURLS_FRONTEND_AFTER:-true}" = "true" ] && [ $EXIT_CODE -eq 0 ]; then
    run_yourls_frontend
fi

cleanup_old_logs

handle_reboot

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ $EXIT_CODE -eq 0 ]; then
    log "✅ Recycle completed successfully"
    notify_success $DURATION
else
    log "❌ Recycle failed with exit code $EXIT_CODE"
    notify_failure $EXIT_CODE $DURATION
fi

rm -f "$LOCK_FILE"
log "🏁 Monthly recycle finished"
exit $EXIT_CODE