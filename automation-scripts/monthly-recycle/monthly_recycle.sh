#!/bin/bash
# ============================================================
# MONTHLY RECYCLE SCRIPT - RUNS sovereign.sh recycle
# ============================================================
# Location: /path/to/digital-independence/automation-scripts/monthly-recycle/monthly_recycle.sh
# Config: /path/to/digital-independence/automation-scripts/monthly-recycle/monthly_recycle.conf
# Action: recycle (pull + down + up) for ALL services
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${SCRIPT_DIR}/monthly_recycle.conf"

if [ -f "$CONF_FILE" ]; then
    source "$CONF_FILE"
else
    echo "❌ Configuration not found: $CONF_FILE"
    echo "📋 Copy template: cp monthly_recycle.conf.example monthly_recycle.conf"
    exit 1
fi

mkdir -p "$LOG_DIR"

TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
LOG_FILE="${LOG_DIR}/monthly_recycle_${TIMESTAMP}.log"
START_TIME=$(date +%s)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    if [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m ${secs}s"
    elif [ $minutes -gt 0 ]; then
        echo "${minutes}m ${secs}s"
    else
        echo "${secs}s"
    fi
}

get_system_info() {
    echo "🖥️  **Hostname** : $(hostname)"
    echo "🐧  **OS**       : $(lsb_release -ds 2>/dev/null || echo "Unknown")"
    echo "🔧  **Kernel**   : $(uname -r)"
    echo "⏱️  **Uptime**   : $(uptime -p | sed 's/up //')"
}

get_disk_usage() {
    df -h / | awk 'NR==2 {print $5 " (" $3 "/" $2 ")"}'
}

get_memory_usage() {
    free -h | awk '/Mem:/ {print $3 "/" $2}'
}

get_docker_info() {
    local running=$(docker ps -q 2>/dev/null | wc -l)
    local stopped=$(docker ps -a -q -f status=exited 2>/dev/null | wc -l)
    local images=$(docker images -q 2>/dev/null | wc -l)
    echo "📦 **Containers** : $running running, $stopped stopped"
    echo "🖼️  **Images**    : $images"
}

format_service_list() {
    local services="$1"
    local formatted=""
    local count=0
    for service in $services; do
        count=$((count + 1))
        formatted="${formatted}- \`${service}\`\n"
        if [ $count -ge 20 ]; then
            break
        fi
    done
    local total=$(echo "$services" | wc -w)
    if [ $total -gt 20 ]; then
        formatted="${formatted}- ... *and $((total - 20)) other services*\n"
    fi
    echo -e "$formatted"
}

send_ntfy() {
    local title="$1"
    local message="$2"
    local priority="${3:-3}"
    local tags="${4:-}"

    [ "$ENABLE_NTFY" != "true" ] && return 0
    [ -z "$NTFY_URL" ] && return 0
    [ -z "$NTFY_TOPIC" ] && return 0

    local escaped=$(echo "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')
    local curl_args=(
        -X POST
        -H "Title: $title"
        -H "Priority: $priority"
        -H "Tags: $tags"
        -H "Markdown: yes"
        -d "$escaped"
        --max-time 10
        --silent
        --show-error
    )

    if [ -n "$NTFY_TOKEN" ]; then
        curl_args+=(-H "Authorization: Bearer $NTFY_TOKEN")
    fi

    if curl "${curl_args[@]}" "${NTFY_URL}/${NTFY_TOPIC}" >/dev/null 2>&1; then
        log "✅ Notification sent: $title"
    else
        log "⚠️ Failed to send notification: $title"
    fi
}

notify_start() {
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    local service_list=$(format_service_list "$SERVICES")
    local total_services=$(echo "$SERVICES" | wc -w)
    local sys_info=$(get_system_info)
    local disk=$(get_disk_usage)
    local mem=$(get_memory_usage)
    local docker_info=$(get_docker_info)

    local message=$(cat <<EOF
# 🔄 **MONTHLY RECYCLE IN PROGRESS**

---

## 📋 **Information**

**⏰ Start Time** | \`${current_time}\` 
**📁 Working Dir** | \`${WORK_DIR}\` 
**📊 Total Services** | **${total_services}** services 
**🎯 Action** | \`recycle\` (pull + down + up - full refresh) 

---

## 🖥️ **System**

${sys_info}

---

## 📦 **Service List** (${total_services})

${service_list}

---

## 💾 **Initial Resources**

**Disk (/)** | ${disk}
**Memory** | ${mem}

${docker_info}

---

## 📝 **Log File**

\`\`\`
${LOG_FILE}
\`\`\`

---
*⚡ Status: Running - Monthly recycle process in progress...*
EOF
)
    send_ntfy "🔄 Monthly Recycle Started" "$message" "4" "arrows_counterclockwise,desktop_computer"
}

notify_success() {
    local duration=$1
    local duration_str=$(format_duration $duration)
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    local sys_info=$(get_system_info)
    local disk=$(get_disk_usage)
    local mem=$(get_memory_usage)
    local docker_info=$(get_docker_info)
    local service_list=$(format_service_list "$SERVICES")
    local total_services=$(echo "$SERVICES" | wc -w)

    local reboot_msg=""
    if [ -f /var/run/reboot-required ]; then
        reboot_msg="\n🔁 **Reboot required!** Please reboot manually or enable AUTO_REBOOT."
    fi

    local message=$(cat <<EOF
# ✅ **MONTHLY RECYCLE COMPLETED!**

---

## 📊 **Summary**

**⏱️ Duration** | **${duration_str}** 
**📦 Services Recycled** | **${total_services}** services 
**✅ Status** | **Successful** 
**⏰ End Time** | \`${end_time}\` 

---

## 🖥️ **System**

${sys_info}

---

## 📦 **Recycled Services**

${service_list}

---

## 💾 **Final Resources**

**Disk (/)** | ${disk} 
**Memory** | ${mem} 

${docker_info}

---

## 🧹 **Cleanup Complete**

- ✅ sovereign.sh recycle completed
- ✅ Old logs cleaned (>${CLEANUP_LOGS_DAYS} days)${reboot_msg}

---

## 📝 **Log File**

\`\`\`
${LOG_FILE}
\`\`\`

---
*🎉 Monthly recycle completed successfully!*
EOF
)
    send_ntfy "✅ Monthly Recycle Completed" "$message" "4" "white_check_mark,calendar"
}

notify_failure() {
    local exit_code=$1
    local duration=$2
    local duration_str=$(format_duration $duration)
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    local sys_info=$(get_system_info)
    local disk=$(get_disk_usage)
    local mem=$(get_memory_usage)
    local docker_info=$(get_docker_info)

    local error_log=$(tail -50 "$LOG_FILE" | grep -iE "error|failed|exception|fatal" | tail -5)
    [ -z "$error_log" ] && error_log="No specific errors found, check full log."

    local message=$(cat <<EOF
# ❌ **MONTHLY RECYCLE FAILED!**

---

## 📊 **Error Summary**

**⏱️ Duration** | **${duration_str}** 
**❌ Exit Code** | \`${exit_code}\` 
**⏰ Failure Time** | \`${end_time}\` 

---

## 🖥️ **System**

${sys_info}

---

## 🔍 **Error Log (last 5 lines)**

\`\`\`
${error_log}
\`\`\`

---

## 🔧 **Troubleshooting**

1. 📖 **Check full log**:
   \`\`\`bash
   tail -100 ${LOG_FILE}
   \`\`\`

2. 🔄 **Run manually**:
   \`\`\`bash
   cd ${WORK_DIR}
   ./sovereign.sh recycle ${SERVICES}
   \`\`\`

3. 🌐 **Check internet connection**:
   \`\`\`bash
   ping -c 4 google.com
   \`\`\`

4. 💾 **Check disk space**:
   \`\`\`bash
   df -h
   docker system df
   \`\`\`

---

## 💾 **Resources**

**Disk (/)** | ${disk}
**Memory** | ${mem}

${docker_info}

---

## 📝 **Log File**

\`\`\`
${LOG_FILE}
\`\`\`

---
*⚠️ **Please investigate and fix the issue immediately!***
EOF
)
    send_ntfy "❌ Monthly Recycle Failed" "$message" "5" "warning,skull,rotating_light"
}

run_yourls_frontend() {
    log "🔗 Running YOURLS frontend script..."
    
    local YOURS_SCRIPT="${WORK_DIR}/yourls/frontend.sh"
    
    if [ ! -f "$YOURS_SCRIPT" ]; then
        log "⚠️ YOURLS frontend script not found: $YOURS_SCRIPT"
        return 1
    fi
    
    if [ ! -x "$YOURS_SCRIPT" ]; then
        log "⚠️ YOURLS frontend script is not executable. Attempting to fix..."
        chmod +x "$YOURS_SCRIPT" || {
            log "❌ Failed to make YOURLS script executable"
            return 1
        }
    fi
    
    log "▶️ Executing: $YOURS_SCRIPT"
    set +e
    bash "$YOURS_SCRIPT" >> "$LOG_FILE" 2>&1
    local YOURS_EXIT=$?
    set -e
    
    if [ $YOURS_EXIT -eq 0 ]; then
        log "✅ YOURLS frontend script completed successfully"
        return 0
    else
        log "❌ YOURLS frontend script failed with exit code $YOURS_EXIT"
        return 1
    fi
}

cleanup_old_logs() {
    log "🧹 Cleaning old logs (> ${CLEANUP_LOGS_DAYS} days)..."
    local deleted=$(find "$LOG_DIR" -name "monthly_recycle_*.log" -mtime +${CLEANUP_LOGS_DAYS} -delete -print 2>/dev/null | wc -l)
    log "✅ Removed $deleted old log files"
}

# Lock file check
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if kill -0 "$PID" 2>/dev/null; then
        log "❌ Another process is running (PID: $PID). Exiting."
        send_ntfy "⏭️ Monthly Recycle Skipped" "Another process is running (PID: $PID)" "2" "no_entry,calendar"
        exit 1
    else
        rm -f "$LOCK_FILE"
    fi
fi
echo $$ > "$LOCK_FILE"

log "🚀 Starting monthly recycle"
notify_start

cd "$WORK_DIR" || {
    log "❌ Failed to enter $WORK_DIR"
    send_ntfy "❌ Monthly Recycle Failed" "Failed to enter directory $WORK_DIR" "5" "warning"
    rm -f "$LOCK_FILE"
    exit 1
}

if [ "$RUN_APT_UPDATE" = true ]; then
    log "📦 Running apt update (optional)..."
    sudo apt update >> "$LOG_FILE" 2>&1 || log "⚠️ apt update failed (non-fatal)"
    sudo apt full-upgrade -y >> "$LOG_FILE" 2>&1 || log "⚠️ apt upgrade failed (non-fatal)"
fi

log "▶️ Executing: ./sovereign.sh recycle $SERVICES"
set +e
./sovereign.sh recycle $SERVICES >> "$LOG_FILE" 2>&1
EXIT_CODE=$?
set -e

if [ "${RUN_YOURLS_FRONTEND_AFTER:-true}" = "true" ] && [ $EXIT_CODE -eq 0 ]; then
    log "🔄 Running YOURLS frontend after recycle..."
    run_yourls_frontend
    YOURLS_FRONTEND_AFTER_EXIT=$?
fi

cleanup_old_logs

if [ -f /var/run/reboot-required ] && [ "$AUTO_REBOOT" = true ]; then
    log "🔁 Reboot required, auto reboot enabled. Rebooting in 30 seconds..."
    send_ntfy "🔁 Reboot Scheduled" "System will reboot in 30 seconds" "4" "warning,repeat"
    sleep 30
    sudo reboot
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ $EXIT_CODE -eq 0 ]; then
    log "✅ Monthly recycle completed successfully"
    notify_success $DURATION
else
    log "❌ Monthly recycle failed with exit code $EXIT_CODE"
    notify_failure $EXIT_CODE $DURATION
fi

rm -f "$LOCK_FILE"
log "🏁 Monthly recycle finished"
exit $EXIT_CODE