#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

COMPOSE_CMD="docker compose"

# ==============================
#  Service definitions
# ==============================
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

SYNAPSE_SUB_SERVICES=("mautrix-telegram" "mautrix-whatsapp")

# ==============================
#  Helper functions
# ==============================
show_help() {
    echo -e "${BLUE}Usage: $0 [OPTIONS] [SERVICE...]${NC}"
    echo ""
    echo "Options:"
    echo "  -h, --help              Tampilkan bantuan ini"
    echo "  -l, --list              Tampilkan daftar service yang tersedia"
    echo "  -a, --all               Jalankan semua service"
    echo "  -d, --down              Stop dan hapus containers"
    echo "  -r, --restart           Restart service"
    echo "  -p, --pull              Pull latest images sebelum menjalankan"
    echo "  -b, --build             Build images sebelum menjalankan"
    echo "  -v, --verbose           Tampilkan output detail"
    echo "  -i, --interactive       Tampilkan menu checkbox untuk memilih layanan"
    echo ""
    echo "Actions:"
    echo "  up                      Start services (default)"
    echo "  down                    Stop services"
    echo "  restart                 Restart services"
    echo "  logs                    Tampilkan logs"
    echo "  ps                      Tampilkan status containers"
    echo ""
    echo "Examples:"
    echo "  $0 portainer                    # Jalankan portainer"
    echo "  $0 -a up                        # Jalankan semua service"
    echo "  $0 -d portainer                 # Stop portainer"
    echo "  $0 -r portainer vaultwarden     # Restart portainer dan vaultwarden"
    echo "  $0 --pull --all up              # Pull dan jalankan semua service"
    echo "  $0                              # Menu interaktif (jika whiptail/dialog tersedia)"
    echo "  $0 -i                           # Paksa menu interaktif"
}

list_services() {
    echo -e "${GREEN}Available services:${NC}"
    for key in "${!SERVICES[@]}"; do
        echo "  - $key (${SERVICES[$key]})"
    done
    echo ""
    echo -e "${YELLOW}Synapse sub-services:${NC}"
    for sub in "${SYNAPSE_SUB_SERVICES[@]}"; do
        echo "  - synapse:$sub"
    done
}

check_service_dir() {
    local service_path=$1
    if [ ! -d "$service_path" ]; then
        echo -e "${RED}Error: Directory $service_path not found${NC}"
        return 1
    fi
    return 0
}

find_compose_file() {
    local service_path=$1
    local compose_file=""
    
    if [ -f "$service_path/docker-compose.yml" ]; then
        compose_file="$service_path/docker-compose.yml"
    elif [ -f "$service_path/docker-compose.yaml" ]; then
        compose_file="$service_path/docker-compose.yaml"
    elif [ -f "$service_path/compose.yml" ]; then
        compose_file="$service_path/compose.yml"
    elif [ -f "$service_path/compose.yaml" ]; then
        compose_file="$service_path/compose.yaml"
    fi
    
    echo "$compose_file"
}

# ==============================
#  Docker compose operations
# ==============================
run_service() {
    local service_name=$1
    local service_path=$2
    local action=$3
    local options=$4
    local compose_file=$(find_compose_file "$service_path")
    
    if [ -z "$compose_file" ]; then
        echo -e "${RED}Error: No compose file found in $service_path${NC}"
        return 1
    fi
    
    cd "$service_path" || return 1
    
    if [ ! -f ".env" ] && [ -f ".env.example" ]; then
        echo -e "${YELLOW}Warning: .env file not found in $service_path${NC}"
        echo -e "${YELLOW}Consider copying .env.example to .env${NC}"
    fi
    
    local cmd="$COMPOSE_CMD -f $(basename "$compose_file")"
    
    if [[ "$options" == *"pull"* ]]; then
        echo -e "${BLUE}Pulling latest images for $service_name...${NC}"
        $cmd pull
    fi
    
    if [[ "$options" == *"build"* ]]; then
        echo -e "${BLUE}Building images for $service_name...${NC}"
        $cmd build
    fi
    
    echo -e "${GREEN}Executing: $action for $service_name${NC}"
    case $action in
        "up")
            if [[ "$options" == *"verbose"* ]]; then
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
        *)
            echo -e "${RED}Error: Unknown action $action${NC}"
            cd - > /dev/null
            return 1
            ;;
    esac
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ $service_name $action completed${NC}"
    else
        echo -e "${RED}✗ $service_name $action failed${NC}"
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
        echo -e "${RED}Error: Sub-service directory $sub_path not found${NC}"
        return 1
    fi
    
    run_service "$sub_service" "$sub_path" "$action" "$options"
}

# ==============================
#  Interactive checkbox menu
# ==============================
interactive_select() {
    if command -v whiptail &> /dev/null; then
        DIALOG_CMD="whiptail"
    elif command -v dialog &> /dev/null; then
        DIALOG_CMD="dialog"
    else
        echo -e "${RED}Error: whiptail atau dialog tidak ditemukan. Tidak dapat menjalankan mode interaktif.${NC}"
        exit 1
    fi

    local checklist_args=()
    checklist_args+=("--checklist" "Pilih layanan yang akan dijalankan (spasi untuk pilih, TAB untuk OK/Batal):" 20 80 15)
    for key in "${!SERVICES[@]}"; do
        checklist_args+=("$key" "${SERVICES[$key]}" "OFF")
    done
    for sub in "${SYNAPSE_SUB_SERVICES[@]}"; do
        local tag="synapse:$sub"
        checklist_args+=("$tag" "synapse sub: $sub" "OFF")
    done

    local selection
    if [ "$DIALOG_CMD" = "whiptail" ]; then
        selection=$(whiptail "${checklist_args[@]}" 3>&1 1>&2 2>&3)
        local whiptail_exit=$?
        if [ $whiptail_exit -ne 0 ]; then
            echo -e "${YELLOW}Dibatalkan oleh pengguna.${NC}"
            exit 0
        fi
    else
        selection=$(dialog --stdout "${checklist_args[@]}")
        local dialog_exit=$?
        if [ $dialog_exit -ne 0 ]; then
            echo -e "${YELLOW}Dibatalkan oleh pengguna.${NC}"
            exit 0
        fi
    fi

    IFS=' ' read -ra SELECTED_SERVICES <<< "$(echo $selection | sed 's/"//g')"
    SERVICES_TO_RUN=("${SELECTED_SERVICES[@]}")

    if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
        echo -e "${RED}Tidak ada layanan yang dipilih. Keluar.${NC}"
        exit 1
    fi

    echo -e "${GREEN}Layanan terpilih: ${SERVICES_TO_RUN[*]}${NC}"
}

# ==============================
#  Main script logic
# ==============================
ACTION="up"
OPTIONS=""
SERVICES_TO_RUN=()
RUN_ALL=false
INTERACTIVE_MODE=false

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
            OPTIONS="${OPTIONS}verbose"
            shift
            ;;
        -i|--interactive)
            INTERACTIVE_MODE=true
            shift
            ;;
        up|down|restart|logs|ps)
            ACTION="$1"
            shift
            ;;
        *)
            SERVICES_TO_RUN+=("$1")
            shift
            ;;
    esac
done

if [ "$INTERACTIVE_MODE" = true ]; then
    SERVICES_TO_RUN=()
    interactive_select
elif [ ${#SERVICES_TO_RUN[@]} -eq 0 ] && [ "$RUN_ALL" = false ]; then
    if command -v whiptail &> /dev/null || command -v dialog &> /dev/null; then
        echo -e "${YELLOW}Tidak ada argumen layanan. Memasuki mode interaktif...${NC}"
        interactive_select
    else
        echo -e "${RED}Error: No service specified${NC}"
        echo -e "Use $0 -l to list available services"
        echo -e "Use $0 -h for help"
        exit 1
    fi
fi

if [ "$RUN_ALL" = false ] && [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
    echo -e "${RED}Error: Tidak ada layanan yang akan diproses.${NC}"
    exit 1
fi

FAILED_SERVICES=()

process_service() {
    local service_key=$1
    local service_path=${SERVICES[$service_key]}
    
    if [ -z "$service_path" ]; then
        if [[ "$service_key" == synapse:* ]]; then
            local sub_service=${service_key#synapse:}
            if [[ " ${SYNAPSE_SUB_SERVICES[@]} " =~ " ${sub_service} " ]]; then
                if ! run_synapse_subservice "$sub_service" "$ACTION" "$OPTIONS"; then
                    FAILED_SERVICES+=("$service_key")
                fi
            else
                echo -e "${RED}Error: Unknown sub-service $service_key${NC}"
                FAILED_SERVICES+=("$service_key")
            fi
        else
            echo -e "${RED}Error: Unknown service $service_key${NC}"
            FAILED_SERVICES+=("$service_key")
        fi
        return
    fi
    
    if ! check_service_dir "$service_path"; then
        FAILED_SERVICES+=("$service_key")
        return
    fi
    
    if ! run_service "$service_key" "$service_path" "$ACTION" "$OPTIONS"; then
        FAILED_SERVICES+=("$service_key")
    fi
}

if [ "$RUN_ALL" = true ]; then
    echo -e "${BLUE}Running $ACTION for all services...${NC}"
    for service in "${!SERVICES[@]}"; do
        process_service "$service"
    done
    for sub in "${SYNAPSE_SUB_SERVICES[@]}"; do
        process_service "synapse:$sub"
    done
else
    for service in "${SERVICES_TO_RUN[@]}"; do
        process_service "$service"
    done
fi

echo ""
echo -e "${BLUE}=== Summary ===${NC}"
if [ ${#FAILED_SERVICES[@]} -eq 0 ]; then
    echo -e "${GREEN}All services completed successfully${NC}"
else
    echo -e "${RED}Failed services: ${FAILED_SERVICES[*]}${NC}"
    exit 1
fi