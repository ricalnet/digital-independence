#!/bin/bash
# ============================================================
# WEEKLY UPDATE SCRIPT - RUNS sovereign.sh update
# ============================================================
# Location: /path/to/digital-independence/automation-scripts/weekly-updates/weekly_updates.sh
# Config: /path/to/digital-independence/automation-scripts/weekly-updates/weekly_updates.conf
# Action: update (pull + up) for registered services
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${SCRIPT_DIR}/weekly_updates.conf"

if [ -f "$CONF_FILE" ]; then
    source "$CONF_FILE"
else
    echo "❌ Configuration not found: $CONF_FILE"
    echo "📋 Copy template: cp weekly_updates.conf.example weekly_updates.conf"
    exit 1
fi

mkdir -p "$LOG_DIR"

TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
LOG_FILE="${LOG_DIR}/weekly_update_${TIMESTAMP}.log"
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
# 🔄 **WEEKLY UPDATE IN PROGRESS**

---

## 📋 **Update Information**

**⏰ Start Time** | \`${current_time}\` 
**📁 Working Dir** | \`${WORK_DIR}\` 
**📊 Total Services** | **${total_services}** services 
**🎯 Action** | \`update\` (pull + up - zero downtime) 

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
*⚡ Status: Running - Please wait until process completes...*
EOF
)
    send_ntfy "🔄 Weekly Update Started" "$message" "3" "arrows_counterclockwise,desktop_computer"
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

    local message=$(cat <<EOF
# ✅ **WEEKLY UPDATE SUCCESSFUL!**

---

## 📊 **Summary**

**⏱️ Duration** | **${duration_str}** 
**📦 Services Updated** | **${total_services}** services 
**✅ Status** | **All successful** 
**⏰ End Time** | \`${end_time}\` 

---

## 🖥️ **System**

${sys_info}

---

## 📦 **Updated Services**

${service_list}

---

## 💾 **Final Resources**

**Disk (/)** | ${disk}
**Memory** | ${mem} 

${docker_info}

---

## 🧹 **Cleanup**

- ✅ Docker system prune (if run by sovereign.sh)
- ✅ Old logs cleaned (>${CLEANUP_LOGS_DAYS} days)

---

## 📝 **Log File**

\`\`\`
${LOG_FILE}
\`\`\`

---
*🎉 All services successfully updated with zero downtime!*
EOF
)
    send_ntfy "✅ Weekly Update Completed" "$message" "3" "white_check_mark,party_popper"
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
# ❌ **WEEKLY UPDATE FAILED!**

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
   ./sovereign.sh update ${SERVICES}
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
    send_ntfy "❌ Weekly Update Failed" "$message" "5" "warning,skull,rotating_light"
}

cleanup_old_logs() {
    log "🧹 Cleaning old logs (> ${CLEANUP_LOGS_DAYS} days)..."
    local deleted=$(find "$LOG_DIR" -name "weekly_update_*.log" -mtime +${CLEANUP_LOGS_DAYS} -delete -print 2>/dev/null | wc -l)
    log "✅ Removed $deleted old log files"
}

# Lock file check
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if kill -0 "$PID" 2>/dev/null; then
        log "❌ Another process is running (PID: $PID). Exiting."
        send_ntfy "⏭️ Weekly Update Skipped" "Another process is running (PID: $PID)" "2" "no_entry,calendar"
        exit 1
    else
        rm -f "$LOCK_FILE"
    fi
fi
echo $$ > "$LOCK_FILE"

log "🚀 Starting weekly update"
notify_start

cd "$WORK_DIR" || {
    log "❌ Failed to enter $WORK_DIR"
    send_ntfy "❌ Weekly Update Failed" "Failed to enter directory $WORK_DIR" "5" "warning"
    rm -f "$LOCK_FILE"
    exit 1
}

# Run sovereign.sh update with services
log "▶️ Executing: ./sovereign.sh update $SERVICES"
set +e
./sovereign.sh update $SERVICES >> "$LOG_FILE" 2>&1
EXIT_CODE=$?
set -e

# Cleanup old logs
cleanup_old_logs

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Send notification based on result
if [ $EXIT_CODE -eq 0 ]; then
    log "✅ Weekly update completed successfully"
    notify_success $DURATION
else
    log "❌ Weekly update failed with exit code $EXIT_CODE"
    notify_failure $EXIT_CODE $DURATION
fi

rm -f "$LOCK_FILE"
log "🏁 Weekly update finished"
exit $EXIT_CODE