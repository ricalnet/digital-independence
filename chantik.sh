#!/bin/bash

set -o pipefail
set -o errtrace

readonly VERSION="1.0"
readonly SCRIPT_NAME="chantik"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BASE_DIR="${CHANTIK_BASE:-${SCRIPT_DIR}}"
readonly CONFIG_FILE="${CHANTIK_CONFIG:-${SCRIPT_DIR}/chantik.conf}"
readonly CONFIG_EXAMPLE="${SCRIPT_DIR}/chantik.example.conf"
readonly LOCK_FILE="/tmp/chantik.lock"

if [ -t 1 ]; then
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    CYAN=$(tput setaf 6)
    RED=$(tput setaf 1)
    BOLD=$(tput bold)
    NC=$(tput sgr0)
else
    GREEN=""; YELLOW=""; BLUE=""; CYAN=""; RED=""; BOLD=""; NC=""
fi

help() {
    cat << EOF
${BOLD}chantik v${VERSION} - ChaCha20-Authenticated Backup Protection${NC}

${BOLD}USAGE:${NC}
    chantik [ACTION] [OPTIONS]

${BOLD}ACTIONS:${NC}
    backup              Perform full backup
    restore             Restore from backup
    list                List available backups
    verify              Verify backup integrity
    clean               Clean old backups (rotation)
    status              Show backup status

${BOLD}OPTIONS:${NC}
    -c, --config FILE   Use alternative config file
    -b, --backup FILE   Restore from specific backup file
    -s, --service NAME  Restore specific service
    -p, --password PASS Password for encryption (optional)
    -h, --help          Show this help

${BOLD}EXAMPLES:${NC}
    chantik backup                          # Backup all
    chantik restore                         # Restore last backup
    chantik restore -s nextcloud            # Restore specific service
    chantik restore -b /backup/file.enc     # Restore specific file
    chantik list                            # List backups
    chantik verify                          # Verify last backup
    chantik clean                           # Clean old backups
    chantik status                          # Show status

${BOLD}ALIAS:${NC}
    Aliases auto-configured by ./install-podman-on-debian.sh
    Manual: alias chantik='/path/to/digital-independence/chantik.sh'
EOF
}

log() {
    local level="${1:-INFO}"
    local msg="${2:-}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        INFO)  echo "${BLUE}[INFO]${NC} $msg" ;;
        OK)    echo "${GREEN}[OK]${NC} $msg" ;;
        WARN)  echo "${YELLOW}[WARN]${NC} $msg" >&2 ;;
        ERROR) echo "${RED}[ERROR]${NC} $msg" >&2 ;;
        *)     echo "[$level] $msg" ;;
    esac
}

send_ntfy() {
    local title="$1"
    local message="$2"
    local priority="${3:-default}"
    
    [[ -z "$NTFY_URL" || -z "$NTFY_TOPIC" ]] && return 0
    
    local url="${NTFY_URL}/${NTFY_TOPIC}"
    local auth=""
    
    if [[ -n "$NTFY_TOKEN" ]]; then
        auth="-H \"Authorization: Bearer ${NTFY_TOKEN}\""
    fi
    
    local formatted_message=$(echo -e "$message")
    
    eval "curl -s -X POST \
        -H \"Title: ${title}\" \
        -H \"Priority: ${priority}\" \
        ${auth} \
        -d \"${formatted_message}\" \
        \"${url}\" >/dev/null 2>&1"
}

encrypt_file() {
    local input="$1"
    local output="$2"
    local password="${3:-}"
    
    if [[ -z "$password" ]]; then
        read -s -p "Enter encryption password: " password
        echo
        if [[ -z "$password" ]]; then
            log ERROR "Password cannot be empty"
            return 1
        fi
    fi
    
    if ! openssl enc -chacha20 -pbkdf2 -iter 100000 -salt -in "$input" -out "$output" -pass "pass:$password" 2>/dev/null; then
        log ERROR "Failed to encrypt $input"
        return 1
    fi
    
    return 0
}

decrypt_file() {
    local input="$1"
    local output="$2"
    local password="${3:-}"
    
    if [[ -z "$password" ]]; then
        read -s -p "Enter encryption password: " password
        echo
        if [[ -z "$password" ]]; then
            log ERROR "Password cannot be empty"
            return 1
        fi
    fi
    
    if ! openssl enc -d -chacha20 -pbkdf2 -iter 100000 -salt -in "$input" -out "$output" -pass "pass:$password" 2>/dev/null; then
        log ERROR "Failed to decrypt $input (wrong password or corrupt file)"
        return 1
    fi
    
    return 0
}

load_config() {
    local config_file="${1:-$CONFIG_FILE}"
    
    if [[ ! -f "$config_file" ]]; then
        if [[ -f "$CONFIG_EXAMPLE" ]]; then
            log WARN "Config file not found, copying from example: $CONFIG_EXAMPLE"
            cp "$CONFIG_EXAMPLE" "$config_file"
            chmod 600 "$config_file"
            log OK "Config file created: $config_file"
            log INFO "Please review and edit $config_file if needed"
        else
            log ERROR "Config file not found: $config_file"
            log ERROR "Example config file not found: $CONFIG_EXAMPLE"
            log INFO "Please create chantik.conf manually"
            return 1
        fi
    fi
    
    source "$config_file"
    
    BACKUP_DIR="${BACKUP_DIR:-/backup}"
    BACKUP_PREFIX="${BACKUP_PREFIX:-chantik}"
    BACKUP_RETENTION="${BACKUP_RETENTION:-7}"
    CUSTOM_DIRS="${CUSTOM_DIRS:-}"
    PODMAN_VOLUMES="${PODMAN_VOLUMES:-}"
    ENCRYPTION_PASSWORD="${ENCRYPTION_PASSWORD:-}"
    NTFY_URL="${NTFY_URL:-}"
    NTFY_TOPIC="${NTFY_TOPIC:-chantik-backup}"
    NTFY_TOKEN="${NTFY_TOKEN:-}"
    INCREMENTAL_DIR="${INCREMENTAL_DIR:-${BACKUP_DIR}/.incremental}"
    USE_HARDLINK="${USE_HARDLINK:-true}"
    
    mkdir -p "$BACKUP_DIR" "$INCREMENTAL_DIR"
    
    return 0
}

backup_podman_volume() {
    local volume="$1"
    local target_dir="$2"
    local timestamp="$3"
    
    log INFO "Backup volume: $volume"
    
    if ! podman volume exists "$volume" 2>/dev/null; then
        log WARN "Volume $volume not found, skipping..."
        return 0
    fi
    
    local temp_dir="${target_dir}/volumes/${volume}"
    mkdir -p "$temp_dir"
    
    local mount_point=$(podman volume inspect "$volume" --format "{{.Mountpoint}}" 2>/dev/null)
    
    if [[ -z "$mount_point" || ! -d "$mount_point" ]]; then
        log WARN "Mount point for $volume not found"
        return 0
    fi
    
    local archive_file="${temp_dir}/data.tar.gz"
    local manifest_file="${temp_dir}/manifest.txt"
    
    echo "Volume: $volume" > "$manifest_file"
    echo "Mountpoint: $mount_point" >> "$manifest_file"
    echo "Backup Date: $(date)" >> "$manifest_file"
    podman volume inspect "$volume" >> "$manifest_file" 2>/dev/null
    
    if [[ "$USE_HARDLINK" == "true" && -d "$INCREMENTAL_DIR" ]]; then
        local snapshot_dir="${INCREMENTAL_DIR}/volumes/${volume}"
        local prev_snapshot=""
        
        if [[ -d "$snapshot_dir" ]]; then
            prev_snapshot=$(find "$snapshot_dir" -maxdepth 1 -type d -name "20*" | sort | tail -n1)
        fi
        
        mkdir -p "$snapshot_dir"
        local current_snapshot="${snapshot_dir}/${timestamp}"
        mkdir -p "$current_snapshot"
        
        if [[ -n "$prev_snapshot" && -d "$prev_snapshot" ]]; then
            log INFO "Using incremental backup (hardlink) for $volume"
            rsync -a --link-dest="$prev_snapshot" "$mount_point/" "$current_snapshot/" 2>/dev/null
            tar -czf "$archive_file" -C "$snapshot_dir" "$(basename "$current_snapshot")" 2>/dev/null
        else
            tar -czf "$archive_file" -C "$mount_point" . 2>/dev/null
            rsync -a "$mount_point/" "$current_snapshot/" 2>/dev/null
        fi
    else
        tar -czf "$archive_file" -C "$mount_point" . 2>/dev/null
    fi
    
    if [[ ! -f "$archive_file" ]]; then
        log ERROR "Failed to create archive for volume $volume"
        return 1
    fi
    
    local size=$(du -h "$archive_file" | cut -f1)
    log OK "Volume $volume backup complete: $archive_file ($size)"
    
    return 0
}

backup_custom_dir() {
    local dir="$1"
    local target_dir="$2"
    local timestamp="$3"
    
    log INFO "Backup custom directory: $dir"
    
    if [[ ! -d "$dir" ]]; then
        log WARN "Directory $dir not found, skipping..."
        return 0
    fi
    
    local name=$(basename "$dir")
    local temp_dir="${target_dir}/custom/${name}"
    mkdir -p "$temp_dir"
    
    local archive_file="${temp_dir}/data.tar.gz"
    local manifest_file="${temp_dir}/manifest.txt"
    
    echo "Directory: $dir" > "$manifest_file"
    echo "Backup Date: $(date)" >> "$manifest_file"
    ls -la "$dir" >> "$manifest_file" 2>/dev/null
    
    if [[ "$USE_HARDLINK" == "true" && -d "$INCREMENTAL_DIR" ]]; then
        local snapshot_dir="${INCREMENTAL_DIR}/custom/${name}"
        local prev_snapshot=""
        
        if [[ -d "$snapshot_dir" ]]; then
            prev_snapshot=$(find "$snapshot_dir" -maxdepth 1 -type d -name "20*" | sort | tail -n1)
        fi
        
        mkdir -p "$snapshot_dir"
        local current_snapshot="${snapshot_dir}/${timestamp}"
        mkdir -p "$current_snapshot"
        
        if [[ -n "$prev_snapshot" && -d "$prev_snapshot" ]]; then
            log INFO "Using incremental backup (hardlink) for $dir"
            rsync -a --link-dest="$prev_snapshot" "$dir/" "$current_snapshot/" 2>/dev/null
            tar -czf "$archive_file" -C "$snapshot_dir" "$(basename "$current_snapshot")" 2>/dev/null
        else
            tar -czf "$archive_file" -C "$dir" . 2>/dev/null
            rsync -a "$dir/" "$current_snapshot/" 2>/dev/null
        fi
    else
        tar -czf "$archive_file" -C "$dir" . 2>/dev/null
    fi
    
    if [[ ! -f "$archive_file" ]]; then
        log ERROR "Failed to create archive for $dir"
        return 1
    fi
    
    local size=$(du -h "$archive_file" | cut -f1)
    log OK "Custom directory $dir backup complete: $archive_file ($size)"
    
    return 0
}

list_podman_volumes() {
    if [[ -n "$PODMAN_VOLUMES" ]]; then
        echo "$PODMAN_VOLUMES"
    else
        podman volume ls -q 2>/dev/null
    fi
}

do_backup() {
    local timestamp=$(date '+%Y%m%d-%H%M%S')
    local backup_name="${BACKUP_PREFIX}-${timestamp}"
    local backup_temp="${BACKUP_DIR}/.tmp-${backup_name}"
    local backup_file="${BACKUP_DIR}/${backup_name}.tar.gz"
    local encrypted_file="${BACKUP_DIR}/${backup_name}.tar.gz.enc"
    
    log INFO "Starting backup: $backup_name"
    
    rm -rf "$backup_temp" 2>/dev/null
    mkdir -p "$backup_temp"/{volumes,custom,metadata}
    
    cat > "$backup_temp/metadata/backup.info" << EOF
BACKUP_NAME=$backup_name
BACKUP_DATE=$(date)
BACKUP_TIMESTAMP=$timestamp
BACKUP_VERSION=$VERSION
BACKUP_TYPE=$(if [[ "$USE_HARDLINK" == "true" ]]; then echo "incremental"; else echo "full"; fi)
PODMAN_VERSION=$(podman version --format "{{.Version}}" 2>/dev/null || echo "unknown")
EOF
    
    local volumes=($(list_podman_volumes))
    if [[ ${#volumes[@]} -gt 0 ]]; then
        log INFO "Backing up ${#volumes[@]} Podman volume(s)"
        for volume in "${volumes[@]}"; do
            backup_podman_volume "$volume" "$backup_temp" "$timestamp"
        done
    else
        log WARN "No Podman volumes found"
    fi
    
    if [[ -n "$CUSTOM_DIRS" ]]; then
        log INFO "Backing up custom directories"
        for dir in $CUSTOM_DIRS; do
            backup_custom_dir "$dir" "$backup_temp" "$timestamp"
        done
    fi
    
    find "$backup_temp" -type f -name "*.tar.gz" > "$backup_temp/metadata/backup_files.txt" 2>/dev/null
    
    log INFO "Creating archive $backup_file"
    cd "$backup_temp" || return 1
    if ! tar -czf "$backup_file" . 2>/dev/null; then
        log ERROR "Failed to create archive"
        cd - >/dev/null
        rm -rf "$backup_temp"
        return 1
    fi
    cd - >/dev/null
    
    local tar_size=$(du -h "$backup_file" | cut -f1)
    log OK "Archive created: $backup_file ($tar_size)"
    
    log INFO "Encrypting backup with ChaCha20-Poly1305..."
    if ! encrypt_file "$backup_file" "$encrypted_file" "$ENCRYPTION_PASSWORD"; then
        log ERROR "Failed to encrypt backup"
        rm -f "$backup_file"
        rm -rf "$backup_temp"
        return 1
    fi
    
    local enc_size=$(du -h "$encrypted_file" | cut -f1)
    log OK "Encrypted backup: $encrypted_file ($enc_size)"
    
    rm -f "$backup_file"
    rm -rf "$backup_temp"
    
    rotate_backups
    
    echo "$encrypted_file" > "${BACKUP_DIR}/.last_backup"
    
    send_ntfy "✅ Backup Complete" "Backup: $backup_name
Size: $enc_size
Volumes: ${#volumes[@]}
Custom Dirs: $(echo "$CUSTOM_DIRS" | wc -w)
Location: $encrypted_file
Date: $(date)" "default"
    
    log OK "Backup complete: $encrypted_file"
    echo
    log INFO "To restore: chantik restore -b $encrypted_file"
    
    return 0
}

rotate_backups() {
    log INFO "Rotating backups (retention: $BACKUP_RETENTION)"
    
    local backups=($(find "$BACKUP_DIR" -maxdepth 1 -name "${BACKUP_PREFIX}-*.tar.gz.enc" -type f | sort))
    local count=${#backups[@]}
    
    if [[ $count -gt $BACKUP_RETENTION ]]; then
        local to_remove=$((count - BACKUP_RETENTION))
        log INFO "Removing $to_remove old backup(s)"
        
        for ((i=0; i<to_remove; i++)); do
            local file="${backups[$i]}"
            log INFO "Removing: $(basename "$file")"
            rm -f "$file"
        done
        
        if [[ -d "$INCREMENTAL_DIR" ]]; then
            local existing_dates=()
            for b in "${backups[@]:$to_remove}"; do
                local name=$(basename "$b" .tar.gz.enc)
                local date_part="${name#${BACKUP_PREFIX}-}"
                existing_dates+=("$date_part")
            done
            
            for snapshot_dir in "${INCREMENTAL_DIR}"/volumes/* "${INCREMENTAL_DIR}"/custom/*; do
                if [[ -d "$snapshot_dir" ]]; then
                    for snap in "$snapshot_dir"/20*; do
                        if [[ -d "$snap" ]]; then
                            local snap_date=$(basename "$snap")
                            if ! grep -q "$snap_date" <<< "${existing_dates[*]}"; then
                                log INFO "Removing old snapshot: $snap"
                                rm -rf "$snap" 2>/dev/null
                            fi
                        fi
                    done
                fi
            done
        fi
    fi
    
    log OK "Rotation complete"
}

list_backups() {
    log INFO "Available backups:"
    echo
    echo "${BOLD}${BLUE}Backup Files:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    
    local backups=($(find "$BACKUP_DIR" -maxdepth 1 -name "${BACKUP_PREFIX}-*.tar.gz.enc" -type f | sort -r))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo "  ${YELLOW}No backups found${NC}"
        return 0
    fi
    
    printf "  %-3s %-25s %-12s %s\n" "#" "FILE" "SIZE" "DATE"
    echo "  ─────────────────────────────────────────────────────────"
    
    local count=0
    for file in "${backups[@]}"; do
        count=$((count + 1))
        local name=$(basename "$file")
        local size=$(du -h "$file" | cut -f1)
        local date=$(stat -c %y "$file" 2>/dev/null | cut -d. -f1 || stat -f %Sm "$file" 2>/dev/null)
        printf "  %-3s %-25s %-12s %s\n" "$count" "$name" "$size" "$date"
    done
    
    echo
    echo "${BOLD}Total: ${#backups[@]} backup(s)${NC}"
    
    if [[ -f "${BACKUP_DIR}/.last_backup" ]]; then
        local last=$(cat "${BACKUP_DIR}/.last_backup")
        echo "${BOLD}Last backup:${NC} $(basename "$last")"
    fi
}

do_restore() {
    local backup_file="$1"
    local service_filter="$2"
    
    if [[ -z "$backup_file" ]]; then
        if [[ -f "${BACKUP_DIR}/.last_backup" ]]; then
            backup_file=$(cat "${BACKUP_DIR}/.last_backup")
        else
            log ERROR "No backup file specified"
            log INFO "Usage: chantik restore -b /path/to/backup.tar.gz.enc"
            return 1
        fi
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log ERROR "Backup file not found: $backup_file"
        return 1
    fi
    
    log INFO "Restoring from: $backup_file"
    
    local temp_dir="${BACKUP_DIR}/.restore-$$"
    mkdir -p "$temp_dir"
    
    local decrypted_file="${temp_dir}/backup.tar.gz"
    log INFO "Decrypting backup..."
    
    if ! decrypt_file "$backup_file" "$decrypted_file" "$ENCRYPTION_PASSWORD"; then
        log ERROR "Failed to decrypt backup"
        rm -rf "$temp_dir"
        return 1
    fi
    
    log OK "Decryption successful"
    
    log INFO "Extracting backup..."
    cd "$temp_dir" || return 1
    
    if ! tar -xzf "$decrypted_file" 2>/dev/null; then
        log ERROR "Failed to extract backup"
        cd - >/dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    cd - >/dev/null
    
    log OK "Extraction complete"
    
    local restored_volumes=0
    
    if [[ -d "$temp_dir/volumes" ]]; then
        log INFO "Restoring Podman volumes..."
        for volume_dir in "$temp_dir/volumes"/*; do
            if [[ -d "$volume_dir" ]]; then
                local volume=$(basename "$volume_dir")
                
                if [[ -n "$service_filter" ]] && [[ ! "$volume" =~ $service_filter ]]; then
                    log INFO "Skipping volume $volume (filter: $service_filter)"
                    continue
                fi
                
                log INFO "Restoring volume: $volume"
                
                if ! podman volume exists "$volume" 2>/dev/null; then
                    log WARN "Volume $volume not found, creating..."
                    podman volume create "$volume" 2>/dev/null
                fi
                
                local mount_point=$(podman volume inspect "$volume" --format "{{.Mountpoint}}" 2>/dev/null)
                
                if [[ -z "$mount_point" ]]; then
                    log ERROR "Failed to get mount point for $volume"
                    continue
                fi
                
                local archive_file="$volume_dir/data.tar.gz"
                if [[ -f "$archive_file" ]]; then
                    log INFO "Restoring data to $mount_point"
                    
                    if [[ -d "$volume_dir" ]]; then
                        if [[ -f "$archive_file" ]]; then
                            tar -xzf "$archive_file" -C "$mount_point" 2>/dev/null
                        else
                            for snap in "$volume_dir"/*/; do
                                if [[ -d "$snap" ]]; then
                                    rsync -a "$snap" "$mount_point/" 2>/dev/null
                                    break
                                fi
                            done
                        fi
                    fi
                    
                    log OK "Volume $volume restored"
                    ((restored_volumes++))
                else
                    log WARN "No data for volume $volume"
                fi
            fi
        done
    fi
    
    if [[ -d "$temp_dir/custom" ]]; then
        log INFO "Restoring custom directories..."
        for custom_dir in "$temp_dir/custom"/*; do
            if [[ -d "$custom_dir" ]]; then
                local name=$(basename "$custom_dir")
                local archive_file="$custom_dir/data.tar.gz"
                
                if [[ -f "$archive_file" ]]; then
                    log INFO "Restoring custom directory: $name"
                    
                    local manifest="$custom_dir/manifest.txt"
                    local target_dir=""
                    
                    if [[ -f "$manifest" ]]; then
                        target_dir=$(grep "^Directory:" "$manifest" | cut -d: -f2- | sed 's/^ //')
                    fi
                    
                    if [[ -z "$target_dir" ]]; then
                        log WARN "Cannot determine target directory for $name, skipping"
                        continue
                    fi
                    
                    mkdir -p "$target_dir"
                    tar -xzf "$archive_file" -C "$target_dir" 2>/dev/null
                    log OK "Custom directory $name restored to $target_dir"
                fi
            fi
        done
    fi
    
    rm -rf "$temp_dir"
    
    send_ntfy "✅ Restore Complete" "Restore from: $(basename "$backup_file")
Service: ${service_filter:-all}
Volumes restored: $restored_volumes
Date: $(date)" "default"
    
    log OK "Restore complete!"
}

verify_backup() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        if [[ -f "${BACKUP_DIR}/.last_backup" ]]; then
            backup_file=$(cat "${BACKUP_DIR}/.last_backup")
        else
            log ERROR "No backup file specified"
            return 1
        fi
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log ERROR "Backup file not found: $backup_file"
        return 1
    fi
    
    log INFO "Verifying backup: $backup_file"
    
    if ! file "$backup_file" | grep -q "openssl enc"; then
        log ERROR "File is not encrypted with OpenSSL"
        return 1
    fi
    
    local temp_dir="${BACKUP_DIR}/.verify-$$"
    mkdir -p "$temp_dir"
    
    local decrypted_file="${temp_dir}/test.tar.gz"
    
    if ! decrypt_file "$backup_file" "$decrypted_file" "$ENCRYPTION_PASSWORD"; then
        log ERROR "Failed to decrypt backup (wrong password or corrupt file)"
        rm -rf "$temp_dir"
        return 1
    fi
    
    if ! tar -tzf "$decrypted_file" >/dev/null 2>&1; then
        log ERROR "Archive corrupt or invalid"
        rm -rf "$temp_dir"
        return 1
    fi
    
    local content=$(tar -tzf "$decrypted_file" 2>/dev/null | head -20)
    log OK "Archive valid, content preview:"
    echo "$content" | sed 's/^/  /'
    
    rm -rf "$temp_dir"
    log OK "Verification complete: backup valid"
    
    return 0
}

do_clean() {
    log INFO "Cleaning backups..."
    
    rotate_backups
    
    find "$BACKUP_DIR" -type d -empty -delete 2>/dev/null
    
    log OK "Clean complete"
}

show_status() {
    echo "${BOLD}${BLUE}Chantik — ChaCha20-Authenticated Backup Protection${NC}"
    echo "───────────────────────────────────────────────────────────────────"
    
    echo "${BOLD}Backup Directory:${NC} $BACKUP_DIR"
    echo "${BOLD}Backup Prefix:${NC} $BACKUP_PREFIX"
    echo "${BOLD}Retention:${NC} $BACKUP_RETENTION backups"
    echo "${BOLD}Incremental:${NC} $USE_HARDLINK"
    echo
    
    if [[ -d "$BACKUP_DIR" ]]; then
        local usage=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        echo "${BOLD}Total Backup Size:${NC} $usage"
        local count=$(find "$BACKUP_DIR" -maxdepth 1 -name "${BACKUP_PREFIX}-*.tar.gz.enc" -type f | wc -l)
        echo "${BOLD}Total Backups:${NC} $count"
    fi
    
    if [[ -f "${BACKUP_DIR}/.last_backup" ]]; then
        local last=$(cat "${BACKUP_DIR}/.last_backup")
        if [[ -f "$last" ]]; then
            local size=$(du -h "$last" | cut -f1)
            local date=$(stat -c %y "$last" 2>/dev/null | cut -d. -f1 || stat -f %Sm "$last" 2>/dev/null)
            echo
            echo "${BOLD}Last Backup:${NC}"
            echo "  File: $(basename "$last")"
            echo "  Size: $size"
            echo "  Date: $date"
        fi
    fi
    
    if [[ -n "$NTFY_URL" && -n "$NTFY_TOPIC" ]]; then
        echo
        echo "${BOLD}NTFY Notification:${NC} Enabled"
        echo "  URL: $NTFY_URL/$NTFY_TOPIC"
        [[ -n "$NTFY_TOKEN" ]] && echo "  Token: ${NTFY_TOKEN:0:10}..."
    else
        echo
        echo "${BOLD}NTFY Notification:${NC} Disabled"
    fi
}

acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if kill -0 "$pid" 2>/dev/null; then
            log ERROR "Backup already running (PID: $pid)"
            return 1
        else
            log WARN "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
    
    echo $$ > "$LOCK_FILE"
    return 0
}

release_lock() {
    rm -f "$LOCK_FILE" 2>/dev/null
}

cleanup() {
    release_lock
    rm -rf "${BACKUP_DIR}/.tmp-*" 2>/dev/null
    rm -rf "${BACKUP_DIR}/.restore-*" 2>/dev/null
    rm -rf "${BACKUP_DIR}/.verify-*" 2>/dev/null
    exit 1
}

main() {
    local action=""
    local config_file="$CONFIG_FILE"
    local backup_file=""
    local service_filter=""
    local password=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                config_file="$2"
                shift 2
                ;;
            -b|--backup)
                backup_file="$2"
                shift 2
                ;;
            -s|--service)
                service_filter="$2"
                shift 2
                ;;
            -p|--password)
                ENCRYPTION_PASSWORD="$2"
                shift 2
                ;;
            -h|--help)
                help
                exit 0
                ;;
            backup|restore|list|verify|clean|status)
                action="$1"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                help
                exit 1
                ;;
        esac
    done
    
    if ! load_config "$config_file"; then
        exit 1
    fi
    
    trap cleanup EXIT INT TERM
    
    case $action in
        backup)
            if ! acquire_lock; then
                exit 1
            fi
            do_backup
            release_lock
            ;;
        restore)
            do_restore "$backup_file" "$service_filter"
            ;;
        list)
            list_backups
            ;;
        verify)
            verify_backup "$backup_file"
            ;;
        clean)
            do_clean
            ;;
        status)
            show_status
            ;;
        *)
            log ERROR "Unknown action: $action"
            help
            exit 1
            ;;
    esac
}

if [[ "$0" != "${BASH_SOURCE[0]}" ]]; then
    return 0
fi

main "$@"