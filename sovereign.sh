#!/bin/bash

set -o pipefail
set -o errtrace

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'

# =============================================================================
# Configuration
# =============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="${SCRIPT_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/sovereign-$(date +%Y%m%d-%H%M%S).log"
readonly TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

COMPOSE_CMD="docker compose"
USE_SUDO=false
DRY_RUN=false

# =============================================================================
# Service definitions
# =============================================================================
declare -A SERVICES
SERVICES=(
    ["dashdot"]="dashdot"
    ["element-web"]="element-web"
    ["homarr"]="homarr"
    ["immich"]="immich-app"
    ["jellyfin"]="jellyfin"
    ["libretranslate"]="LibreTranslate"
    ["nextcloud"]="nextcrow-docker"
    ["ntfy"]="ntfy"
    ["open-webui"]="open-webui"
    ["pihole"]="pi-hole"
    ["portainer"]="portainer"
    ["searxng"]="searxng-docker"
    ["synapse"]="synapse"
    ["uptime-kuma"]="uptime-kuma"
    ["vaultwarden"]="vaultwarden"
    ["mediawiki"]="wiki"
    ["yourls"]="yourls"
)

readonly SYNAPSE_SUB_SERVICES=("mautrix-telegram" "mautrix-whatsapp")

declare -A DEPENDENCIES
DEPENDENCIES=(
    ["synapse:mautrix-telegram"]="synapse"
    ["synapse:mautrix-whatsapp"]="synapse"
    ["immich"]="postgres redis"
    ["nextcloud"]="mariadb"
    ["yourls"]="mysql"
)

# =============================================================================
# Logging
# =============================================================================
init_logging() {
    mkdir -p "$LOG_DIR"
    exec 3>&1 4>&2
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
    echo "[OK] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_debug() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${DIM}[DEBUG]${NC} $1"
    fi
    echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

print_header() {
    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}  $1${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_separator() {
    echo -e "${DIM}─────────────────────────────────────────────────────────────────────${NC}"
}

# =============================================================================
# Error handling
# =============================================================================
error_handler() {
    local line_no=$1
    local error_code=$2
    log_error "Script failed at line $line_no with exit code $error_code"
    echo ""
    log_info "Check log file for details: $LOG_FILE"
}

trap 'error_handler ${LINENO} $?' ERR

# =============================================================================
# Helper
# =============================================================================
show_help() {
    echo -e "${BOLD}${BLUE}Digital Independence by Ricalnet${NC}"
    echo -e "${DIM}SOVEREIGN.SH v2.0.0${NC}"
    echo ""
    echo -e "${BOLD}USAGE:${NC}"
    echo -e "    $0 [OPTIONS] [ACTION] [SERVICE...]"
    echo ""
    echo -e "${BOLD}OPTIONS:${NC}"
    echo -e "    -h, --help              Show this help message"
    echo -e "    -l, --list              List all available services"
    echo -e "    -a, --all               Run action on all services"
    echo -e "    -d, --down              Stop and remove containers (ACTION)"
    echo -e "    -r, --restart           Restart services (ACTION)"
    echo -e "    -p, --pull              Pull latest images before action"
    echo -e "    -b, --build             Build images before action"
    echo -e "    -v, --verbose           Show detailed output"
    echo -e "    -i, --interactive       Interactive checkbox menu"
    echo -e "    -n, --dry-run           Show what would be executed (no changes)"
    echo -e "    -s, --sudo              Use sudo for docker commands"
    echo -e "    --no-color              Disable colored output"
    echo ""
    echo -e "${BOLD}ACTIONS:${NC}"
    echo -e "    up                      Start services ${GREEN}(default)${NC}"
    echo -e "    down                    Stop and remove services"
    echo -e "    restart                 Restart services"
    echo -e "    logs                    Show logs (last 50 lines)"
    echo -e "    ps                      Show container status"
    echo -e "    prune                   Clean up unused resources"
    echo ""
    echo -e "${BOLD}COMBINED ACTIONS:${NC}"
    echo -e "    recycle                 ${CYAN}PULL → DOWN → UP${NC} (full refresh with new images)"
    echo -e "    update                  PULL → UP (update without downtime)"
    echo -e "    fresh                   DOWN → UP (recreate without pull)"
    echo ""
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo -e "    $0 portainer                                    # Start portainer"
    echo -e "    $0 -a up                                        # Start all services"
    echo -e "    $0 -d portainer                                 # Stop portainer"
    echo -e "    $0 -r portainer vaultwarden                     # Restart services"
    echo -e "    $0 --pull --all up                              # Update all services"
    echo -e "    $0 recycle synapse                              # Full refresh synapse"
    echo -e "    $0 recycle synapse synapse:mautrix-telegram     # Refresh synapse + bridges"
    echo -e "    $0 fresh immich                                 # Recreate immich only"
    echo -e "    $0 -n up portainer                              # Dry run"
    echo -e "    $0 -i                                           # Interactive mode"
    echo ""
    echo -e "${BOLD}SERVICE NAMING:${NC}"
    echo -e "    • Main services: use service name directly"
    echo -e "    • Synapse sub-services: ${CYAN}synapse:mautrix-telegram${NC}, ${CYAN}synapse:mautrix-whatsapp${NC}"
    echo ""
    echo -e "${BOLD}RECYCLE SEQUENCE:${NC}"
    echo -e "    ${CYAN}1. PULL${NC}  → Download latest images (container still running)"
    echo -e "    ${CYAN}2. DOWN${NC}  → Stop and remove old container"
    echo -e "    ${CYAN}3. UP${NC}    → Start new container with fresh image and config"
}

list_services() {
    print_header "Available Services"
    
    echo -e "${BOLD}${GREEN}Main Services:${NC}"
    for key in $(printf '%s\n' "${!SERVICES[@]}" | sort); do
        printf "  ${CYAN}%-20s${NC} → %s\n" "$key" "${SERVICES[$key]}"
    done
    
    echo ""
    echo -e "${BOLD}${YELLOW}Synapse Sub-Services:${NC}"
    for sub in "${SYNAPSE_SUB_SERVICES[@]}"; do
        printf "  ${CYAN}synapse:%-18s${NC}\n" "$sub"
    done
    
    echo ""
    echo -e "${BOLD}${DIM}Total: ${#SERVICES[@]} main services + ${#SYNAPSE_SUB_SERVICES[@]} sub-services${NC}"
}

check_service_dir() {
    local service_path=$1
    if [ ! -d "$service_path" ]; then
        log_error "Directory not found: $service_path"
        return 1
    fi
    return 0
}

find_compose_file() {
    local service_path=$1
    local compose_file=""
    
    for pattern in "docker-compose.yml" "docker-compose.yaml" "compose.yml" "compose.yaml"; do
        if [ -f "$service_path/$pattern" ]; then
            compose_file="$service_path/$pattern"
            break
        fi
    done
    
    echo "$compose_file"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        return 1
    fi
    
    local docker_cmd="docker"
    if [[ "$USE_SUDO" == true ]]; then
        docker_cmd="sudo docker"
    fi
    
    if ! $docker_cmd info &> /dev/null; then
        log_error "Docker daemon is not running or insufficient permissions"
        log_info "Try running with -s flag or add user to docker group"
        return 1
    fi
    
    return 0
}

check_dependencies() {
    local service_key=$1
    local deps=${DEPENDENCIES[$service_key]:-""}
    
    if [ -n "$deps" ] && [[ "$ACTION" != "down" ]]; then
        log_debug "Service $service_key depends on: $deps"
    fi
}

# =============================================================================
# Docker compose operations
# =============================================================================
run_service() {
    local service_name=$1
    local service_path=$2
    local action=$3
    local options=$4
    local compose_file=$(find_compose_file "$service_path")
    
    if [ -z "$compose_file" ]; then
        log_error "No compose file found in $service_path"
        return 1
    fi
    
    cd "$service_path" || return 1
    
    if [ ! -f ".env" ] && [ -f ".env.example" ]; then
        log_warning ".env file not found in $service_path"
        log_info "Copy .env.example to .env if you need custom configuration"
    fi
    
    local cmd="$COMPOSE_CMD -f $(basename "$compose_file")"
    if [[ "$USE_SUDO" == true ]]; then
        cmd="sudo $cmd"
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would execute in $service_path:"
        echo "  Directory: $service_path"
        echo "  Compose file: $(basename "$compose_file")"
        echo "  Action: $action"
        echo "  Options: $options"
        cd - > /dev/null
        return 0
    fi
    
    if [[ "$options" == *"pull"* ]] && [[ "$action" != "down" ]]; then
        log_info "Pulling latest images for $service_name..."
        if [[ "$VERBOSE" == true ]]; then
            $cmd pull
        else
            $cmd pull > /dev/null 2>&1
        fi
        if [ $? -ne 0 ]; then
            log_error "Failed to pull images for $service_name"
            cd - > /dev/null
            return 1
        fi
        log_success "Images pulled for $service_name"
    fi
    
    if [[ "$options" == *"build"* ]] && [[ "$action" != "down" ]]; then
        log_info "Building images for $service_name..."
        if [[ "$VERBOSE" == true ]]; then
            $cmd build
        else
            $cmd build > /dev/null 2>&1
        fi
        if [ $? -ne 0 ]; then
            log_error "Failed to build images for $service_name"
            cd - > /dev/null
            return 1
        fi
        log_success "Images built for $service_name"
    fi
    
    log_info "Executing: $action for $service_name"
    
    case $action in
        "up")
            if [[ "$VERBOSE" == true ]]; then
                $cmd up -d
            else
                $cmd up -d > /dev/null 2>&1
            fi
            ;;
        "down")
            $cmd down
            ;;
        "restart")
            $cmd restart
            ;;
        "logs")
            $cmd logs --tail=50
            ;;
        "ps")
            $cmd ps
            ;;
        "prune")
            docker system prune -f
            ;;
        *)
            log_error "Unknown action: $action"
            cd - > /dev/null
            return 1
            ;;
    esac
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        log_success "$service_name $action completed"
    else
        log_error "$service_name $action failed (exit code: $exit_code)"
    fi
    
    cd - > /dev/null
    return $exit_code
}

run_synapse_subservice() {
    local sub_service=$1
    local action=$2
    local options=$3
    local sub_path="synapse/$sub_service"
    
    if [ ! -d "$sub_path" ]; then
        log_error "Sub-service directory not found: $sub_path"
        return 1
    fi
    
    if [[ "$action" == "up" ]] || [[ "$action" == "recycle" ]] || [[ "$action" == "fresh" ]]; then
        if [[ "$action" != "down" ]]; then
            check_dependencies "synapse:$sub_service"
        fi
    fi
    
    run_service "$sub_service" "$sub_path" "$action" "$options"
}

do_recycle() {
    local service_key=$1
    local service_path=${SERVICES[$service_key]}
    
    print_separator
    log_info "🔄 RECYCLE: $service_key"
    log_info "Sequence: ${CYAN}PULL → DOWN → UP${NC}"
    print_separator
    
    log_info "📥 [1/3] Pulling latest images for $service_key..."
    if ! run_service "$service_key" "$service_path" "up" "pull"; then
        log_warning "Pull had issues, but continuing with recycle..."
    fi
    log_success "Pull completed for $service_key"
    
    log_info "🛑 [2/3] Stopping old container for $service_key..."
    if ! run_service "$service_key" "$service_path" "down" ""; then
        log_error "Failed to stop $service_key"
        return 1
    fi
    log_success "Old container stopped for $service_key"
    
    log_info "🚀 [3/3] Starting new container for $service_key..."
    if ! run_service "$service_key" "$service_path" "up" ""; then
        log_error "Failed to start $service_key"
        return 1
    fi
    log_success "New container started for $service_key"
    
    log_success "✅ $service_key recycled successfully (pull → down → up)"
    return 0
}

do_recycle_sub() {
    local sub_service=$1
    local sub_path="synapse/$sub_service"
    
    print_separator
    log_info "🔄 RECYCLE: synapse:$sub_service"
    log_info "Sequence: ${CYAN}PULL → DOWN → UP${NC}"
    print_separator
    
    log_info "📥 [1/3] Pulling latest images for synapse:$sub_service..."
    if ! run_service "$sub_service" "$sub_path" "up" "pull"; then
        log_warning "Pull had issues, but continuing with recycle..."
    fi
    log_success "Pull completed for synapse:$sub_service"
    
    log_info "🛑 [2/3] Stopping old container for synapse:$sub_service..."
    if ! run_service "$sub_service" "$sub_path" "down" ""; then
        log_error "Failed to stop synapse:$sub_service"
        return 1
    fi
    log_success "Old container stopped for synapse:$sub_service"
    
    log_info "🚀 [3/3] Starting new container for synapse:$sub_service..."
    if ! run_service "$sub_service" "$sub_path" "up" ""; then
        log_error "Failed to start synapse:$sub_service"
        return 1
    fi
    log_success "New container started for synapse:$sub_service"
    
    log_success "✅ synapse:$sub_service recycled successfully (pull → down → up)"
    return 0
}

do_fresh() {
    local service_key=$1
    local service_path=${SERVICES[$service_key]}
    
    print_separator
    log_info "🔄 FRESH: $service_key"
    log_info "Sequence: ${CYAN}DOWN → UP${NC} (no pull)"
    print_separator
    
    log_info "🛑 [1/2] Stopping container for $service_key..."
    if ! run_service "$service_key" "$service_path" "down" ""; then
        log_error "Failed to stop $service_key"
        return 1
    fi
    log_success "Container stopped for $service_key"
    
    log_info "🚀 [2/2] Starting container for $service_key..."
    if ! run_service "$service_key" "$service_path" "up" ""; then
        log_error "Failed to start $service_key"
        return 1
    fi
    log_success "Container started for $service_key"
    
    log_success "✅ $service_key fresh restart completed (down → up)"
    return 0
}

do_fresh_sub() {
    local sub_service=$1
    local sub_path="synapse/$sub_service"
    
    print_separator
    log_info "🔄 FRESH: synapse:$sub_service"
    log_info "Sequence: ${CYAN}DOWN → UP${NC} (no pull)"
    print_separator
    
    log_info "🛑 [1/2] Stopping container for synapse:$sub_service..."
    if ! run_service "$sub_service" "$sub_path" "down" ""; then
        log_error "Failed to stop synapse:$sub_service"
        return 1
    fi
    log_success "Container stopped for synapse:$sub_service"
    
    log_info "🚀 [2/2] Starting container for synapse:$sub_service..."
    if ! run_service "$sub_service" "$sub_path" "up" ""; then
        log_error "Failed to start synapse:$sub_service"
        return 1
    fi
    log_success "Container started for synapse:$sub_service"
    
    log_success "✅ synapse:$sub_service fresh restart completed (down → up)"
    return 0
}

do_update() {
    local service_key=$1
    local service_path=${SERVICES[$service_key]}
    
    print_separator
    log_info "📦 UPDATE: $service_key"
    log_info "Sequence: ${CYAN}PULL → UP${NC} (zero downtime)"
    print_separator
    
    log_info "📥 [1/2] Pulling latest images for $service_key..."
    if ! run_service "$service_key" "$service_path" "up" "pull"; then
        log_error "Failed to pull images for $service_key"
        return 1
    fi
    log_success "Pull completed for $service_key"
    
    log_info "🚀 [2/2] Starting/updating container for $service_key..."
    if ! run_service "$service_key" "$service_path" "up" ""; then
        log_error "Failed to start $service_key"
        return 1
    fi
    log_success "Container updated for $service_key"
    
    log_success "✅ $service_key updated successfully (pull → up)"
    return 0
}

do_update_sub() {
    local sub_service=$1
    local sub_path="synapse/$sub_service"
    
    print_separator
    log_info "📦 UPDATE: synapse:$sub_service"
    log_info "Sequence: ${CYAN}PULL → UP${NC} (zero downtime)"
    print_separator
    
    log_info "📥 [1/2] Pulling latest images for synapse:$sub_service..."
    if ! run_service "$sub_service" "$sub_path" "up" "pull"; then
        log_error "Failed to pull images for synapse:$sub_service"
        return 1
    fi
    log_success "Pull completed for synapse:$sub_service"
    
    log_info "🚀 [2/2] Starting/updating container for synapse:$sub_service..."
    if ! run_service "$sub_service" "$sub_path" "up" ""; then
        log_error "Failed to start synapse:$sub_service"
        return 1
    fi
    log_success "Container updated for synapse:$sub_service"
    
    log_success "✅ synapse:$sub_service updated successfully (pull → up)"
    return 0
}

# =============================================================================
# Checkbox menu
# =============================================================================
interactive_select() {
    if command -v whiptail &> /dev/null; then
        DIALOG_CMD="whiptail"
    elif command -v dialog &> /dev/null; then
        DIALOG_CMD="dialog"
    else
        log_error "whiptail or dialog not found. Install one of them for interactive mode."
        exit 1
    fi

    local checklist_args=()
    checklist_args+=("--checklist" "Select services to manage (Space to select, Tab to OK):" 20 80 15)
    
    for key in $(printf '%s\n' "${!SERVICES[@]}" | sort); do
        checklist_args+=("$key" "${SERVICES[$key]}" "OFF")
    done
    
    for sub in "${SYNAPSE_SUB_SERVICES[@]}"; do
        local tag="synapse:$sub"
        checklist_args+=("$tag" "synapse sub: $sub" "OFF")
    done

    local selection
    if [ "$DIALOG_CMD" = "whiptail" ]; then
        selection=$(whiptail "${checklist_args[@]}" 3>&1 1>&2 2>&3)
        local exit_code=$?
        if [ $exit_code -ne 0 ]; then
            echo -e "${YELLOW}Cancelled by user.${NC}"
            exit 0
        fi
    else
        selection=$(dialog --stdout "${checklist_args[@]}")
        local exit_code=$?
        if [ $exit_code -ne 0 ]; then
            echo -e "${YELLOW}Cancelled by user.${NC}"
            exit 0
        fi
    fi

    IFS=' ' read -ra SELECTED_SERVICES <<< "$(echo "$selection" | sed 's/"//g')"
    SERVICES_TO_RUN=("${SELECTED_SERVICES[@]}")

    if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
        log_error "No services selected. Exiting."
        exit 1
    fi

    echo -e "${GREEN}Selected services: ${SERVICES_TO_RUN[*]}${NC}"
}

# =============================================================================
# Process service
# =============================================================================
process_service() {
    local service_key=$1
    
    if [[ "$service_key" == synapse:* ]]; then
        local sub_service=${service_key#synapse:}
        if [[ " ${SYNAPSE_SUB_SERVICES[*]} " =~ " ${sub_service} " ]]; then
            case "$COMBINED_ACTION" in
                "recycle") do_recycle_sub "$sub_service" ;;
                "fresh")   do_fresh_sub "$sub_service" ;;
                "update")  do_update_sub "$sub_service" ;;
                *)         run_synapse_subservice "$sub_service" "$ACTION" "$OPTIONS" ;;
            esac
            return $?
        else
            log_error "Unknown sub-service: $service_key"
            return 1
        fi
    fi
    
    local service_path=${SERVICES[$service_key]}
    if [ -z "$service_path" ]; then
        log_error "Unknown service: $service_key"
        return 1
    fi
    
    if ! check_service_dir "$service_path"; then
        return 1
    fi
    
    check_dependencies "$service_key"
    
    case "$COMBINED_ACTION" in
        "recycle") do_recycle "$service_key" ;;
        "fresh")   do_fresh "$service_key" ;;
        "update")  do_update "$service_key" ;;
        *)         run_service "$service_key" "$service_path" "$ACTION" "$OPTIONS" ;;
    esac
    return $?
}

# =============================================================================
# Main script
# =============================================================================
main() {
    ACTION="up"
    COMBINED_ACTION=""
    OPTIONS=""
    SERVICES_TO_RUN=()
    RUN_ALL=false
    INTERACTIVE_MODE=false
    VERBOSE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                list_services
                exit 0
                ;;
            -a|--all)
                RUN_ALL=true
                shift
                ;;
            -d|--down)
                ACTION="down"
                shift
                ;;
            -r|--restart)
                ACTION="restart"
                shift
                ;;
            -p|--pull)
                OPTIONS="${OPTIONS}pull"
                shift
                ;;
            -b|--build)
                OPTIONS="${OPTIONS}build"
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -i|--interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -s|--sudo)
                USE_SUDO=true
                COMPOSE_CMD="sudo docker compose"
                shift
                ;;
            --no-color)
                export NO_COLOR=1
                shift
                ;;
            recycle)
                COMBINED_ACTION="recycle"
                ACTION="recycle"
                shift
                ;;
            fresh)
                COMBINED_ACTION="fresh"
                ACTION="fresh"
                shift
                ;;
            update)
                COMBINED_ACTION="update"
                ACTION="update"
                shift
                ;;
            up|down|restart|logs|ps|prune)
                ACTION="$1"
                shift
                ;;
            *)
                SERVICES_TO_RUN+=("$1")
                shift
                ;;
        esac
    done
    
    init_logging
    
    print_header "SOVEREIGN.SH v2.0.0 by Ricalnet"
    log_info "Started at: $TIMESTAMP"
    log_debug "Log file: $LOG_FILE"
    log_debug "Script directory: $SCRIPT_DIR"
    
    if [[ "$NO_COLOR" == "1" ]]; then
        export NC='' RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE='' BOLD='' DIM=''
    fi
    
    if ! check_docker; then
        exit 1
    fi
    
    if [ "$INTERACTIVE_MODE" = true ]; then
        interactive_select
    elif [ ${#SERVICES_TO_RUN[@]} -eq 0 ] && [ "$RUN_ALL" = false ]; then
        if command -v whiptail &> /dev/null || command -v dialog &> /dev/null; then
            log_info "No services specified. Starting interactive mode..."
            interactive_select
        else
            log_error "No service specified"
            echo -e "Use $0 -l to list available services"
            echo -e "Use $0 -h for help"
            exit 1
        fi
    fi
    
    if [ "$RUN_ALL" = true ]; then
        SERVICES_TO_RUN=()
        for service in $(printf '%s\n' "${!SERVICES[@]}" | sort); do
            SERVICES_TO_RUN+=("$service")
        done
        for sub in "${SYNAPSE_SUB_SERVICES[@]}"; do
            SERVICES_TO_RUN+=("synapse:$sub")
        done
    fi
    
    if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
        log_error "No services to process"
        exit 1
    fi
    
    print_separator
    log_info "Execution Plan:"
    if [ -n "$COMBINED_ACTION" ]; then
        case "$COMBINED_ACTION" in
            "recycle") echo -e "  ${CYAN}Mode:      RECYCLE (Pull → Down → Up)${NC}" ;;
            "fresh")   echo -e "  ${CYAN}Mode:      FRESH (Down → Up)${NC}" ;;
            "update")  echo -e "  ${CYAN}Mode:      UPDATE (Pull → Up)${NC}" ;;
        esac
    else
        echo -e "  ${CYAN}Action:    $ACTION${NC}"
    fi
    if [ -n "$OPTIONS" ]; then
        echo -e "  ${CYAN}Options:   ${OPTIONS}${NC}"
    fi
    echo -e "  ${CYAN}Services:  ${#SERVICES_TO_RUN[@]} service(s)${NC}"
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${YELLOW}Mode:      DRY RUN (no changes)${NC}"
    fi
    print_separator
    echo ""
    
    local FAILED_SERVICES=()
    local SUCCESSFUL_SERVICES=()
    
    for service in "${SERVICES_TO_RUN[@]}"; do
        if process_service "$service"; then
            SUCCESSFUL_SERVICES+=("$service")
        else
            FAILED_SERVICES+=("$service")
        fi
        echo ""
    done
    
    print_header "Execution Summary"
    echo -e "${BOLD}Total services:${NC} ${#SERVICES_TO_RUN[@]}"
    echo -e "${GREEN}Successful:${NC} ${#SUCCESSFUL_SERVICES[@]}"
    echo -e "${RED}Failed:${NC} ${#FAILED_SERVICES[@]}"
    
    if [ ${#SUCCESSFUL_SERVICES[@]} -gt 0 ]; then
        echo ""
        echo -e "${GREEN}Successful services:${NC}"
        for service in "${SUCCESSFUL_SERVICES[@]}"; do
            echo "  ✓ $service"
        done
    fi
    
    if [ ${#FAILED_SERVICES[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}Failed services:${NC}"
        for service in "${FAILED_SERVICES[@]}"; do
            echo "  ✗ $service"
        done
        echo ""
        log_error "Some services failed to process"
        log_info "Check log file: $LOG_FILE"
        exit 1
    fi
    
    echo ""
    log_success "All services completed successfully!"
    echo -e "${DIM}Log saved to: $LOG_FILE${NC}"
    echo ""
    
    exit 0
}

main "$@"