#!/bin/bash

set -o pipefail
set -o errtrace

readonly VERSION="1.1"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BASE_DIR="${DIPEN_BASE:-${SCRIPT_DIR}}"

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

declare -A SERVICES=(
    ["authentik"]="authentik"
    ["dashdot"]="dashdot"
    ["element-web"]="element-web"
    ["homarr"]="homarr"
    ["immich"]="immich"
    ["jellyfin"]="jellyfin"
    ["libretranslate"]="libretranslate"
    ["linkstack"]="linkstack"
    ["mastodon"]="mastodon"
    ["mediawiki"]="wiki"
    ["navidrome"]="navidrome"
    ["nextcloud"]="nextcloud"
    ["ntfy"]="ntfy"
    ["open-webui"]="open-webui"
    ["pi-hole"]="pi-hole"
    ["portainer"]="portainer"
    ["searxng"]="searxng"
    ["synapse"]="synapse"
    ["synapse-mautrix"]="synapse/mautrix"
    ["uptime-kuma"]="uptime-kuma"
    ["vaultwarden"]="vaultwarden"
    ["wazuh"]="wazuh"
    ["yourls"]="yourls"
)

declare -A CONTAINER_PATTERNS=(
    ["synapse-mautrix"]="mautrix"
)

help() {
    cat << EOF
${BOLD}dipen v${VERSION} - Podman Orchestration Tool for Digital Independence${NC}
${BOLD}${BLUE}Issues: https://github.com/ricalnet/digital-independence/issues ${NC}

${BOLD}USAGE:${NC}
    dipen [ACTION] [SERVICE...] [OPTIONS]

${BOLD}ACTIONS:${NC}
    env                 Edit .env file (create from .env.example if missing)
    up                  Start services
    down                Stop services
    restart             Restart services
    pull                Pull latest images
    logs                Show logs (last 50 lines)
    ps                  Show status
    prune               Clean unused resources
    recycle             Pull → Down → Up
    update              Pull → Up
    fresh               Down → Up

${BOLD}OPTIONS:${NC}
    help                Show this help
    version             Show version
    list                List services
    all                 Run on all services
    dry-run             Show what would be executed

${BOLD}EXAMPLES:${NC}
    dipen list
    dipen env nextcloud immich
    dipen env n*
    dipen up nextcloud
    dipen down nextcloud
    dipen restart nextcloud
    dipen pull nextcloud
    dipen logs nextcloud
    dipen ps nextcloud
    dipen prune nextcloud
    dipen update nextcloud
    dipen fresh nextcloud
    dipen recycle nextcloud
    dipen all up
    dipen dry-run up nextcloud
    dipen up n*

${BOLD}ALIAS:${NC}
    Aliases auto-configured by ./install-podman-on-debian.sh
    Manual: alias dipen='/path/to/digital-independence/dipen.sh'
EOF
}

version() { echo "dipen v${VERSION}"; }

list() {
    echo "${BOLD}${BLUE}Available Services:${NC}"
    echo
    for key in $(printf '%s\n' "${!SERVICES[@]}" | sort); do
        printf "  ${CYAN}%-20s${NC} → %s\n" "$key" "${SERVICES[$key]}"
    done
    echo
    echo "${BOLD}Total: ${#SERVICES[@]} services${NC}"
}

check() {
    command -v podman &>/dev/null || { echo "${RED}Error:${NC} Podman not installed"; return 1; }
    command -v podman-compose &>/dev/null || { echo "${RED}Error:${NC} podman-compose not installed"; return 1; }
    return 0
}

edit_env() {
    local name=$1
    local path="${SERVICES[$name]}"
    local env_file="$BASE_DIR/$path/.env"
    local env_example="$BASE_DIR/$path/.env.example"
    
    if [[ ! -d "$BASE_DIR/$path" ]]; then
        echo "${RED}Error:${NC} Directory not found: $BASE_DIR/$path"
        return 1
    fi
    
    if [[ ! -f "$env_file" && -f "$env_example" ]]; then
        echo "${YELLOW}⚠${NC} .env not found for $name, creating from .env.example"
        cp "$env_example" "$env_file"
        echo "${GREEN}✓${NC} Created $env_file"
    fi
    
    if [[ ! -f "$env_file" ]]; then
        echo "${RED}Error:${NC} No .env or .env.example found for $name"
        return 1
    fi
    
    local editor="${EDITOR:-nano}"
    echo "${BLUE}▶${NC} Editing $env_file with $editor..."
    $editor "$env_file"
    
    if [[ $? -eq 0 ]]; then
        echo "${GREEN}✓${NC} $name .env edited successfully"
        return 0
    else
        echo "${RED}✗${NC} Failed to edit $name .env"
        return 1
    fi
}

compose_file() {
    local path="$BASE_DIR/$1"
    for f in "docker-compose.yml" "docker-compose.yaml" "compose.yml" "compose.yaml"; do
        [[ -f "$path/$f" ]] && echo "$path/$f" && return
    done
}

expand() {
    local pattern=$1
    if [[ "$pattern" == *"*"* ]]; then
        local regex="${pattern//\*/.*}"
        for key in "${!SERVICES[@]}"; do
            [[ "$key" =~ ^$regex$ ]] && echo "$key"
        done
    else
        echo "$pattern"
    fi
}

is_running() {
    local name=$1
    local pattern="${CONTAINER_PATTERNS[$name]:-$name}"
    
    if [[ "$pattern" == *"*"* ]]; then
        podman ps --format "{{.Names}}" 2>/dev/null | grep -q "$pattern"
    else
        podman ps --filter "name=$pattern" --format "{{.Status}}" 2>/dev/null | grep -q "Up"
    fi
}

is_existing() {
    local name=$1
    local pattern="${CONTAINER_PATTERNS[$name]:-$name}"
    
    if [[ "$pattern" == *"*"* ]]; then
        podman ps -a --format "{{.Names}}" 2>/dev/null | grep -q "$pattern"
    else
        podman ps -a --filter "name=$pattern" --format "{{.Status}}" 2>/dev/null | grep -q .
    fi
}

get_status() {
    local name=$1
    local pattern="${CONTAINER_PATTERNS[$name]:-$name}"
    
    if [[ "$pattern" == *"*"* ]]; then
        if podman ps --format "{{.Names}}" 2>/dev/null | grep -q "$pattern"; then
            echo "running"
        elif podman ps -a --format "{{.Names}}" 2>/dev/null | grep -q "$pattern"; then
            echo "exited"
        else
            echo "not created"
        fi
    else
        local status=$(podman ps --filter "name=$pattern" --format "{{.Status}}" 2>/dev/null)
        if [[ -n "$status" ]]; then
            echo "$status"
        elif podman ps -a --filter "name=$pattern" --format "{{.Status}}" 2>/dev/null | grep -q .; then
            echo "exited"
        else
            echo "not created"
        fi
    fi
}

run() {
    local name=$1 path=$2 action=$3
    local compose=$(compose_file "$path")
    
    [[ -d "$BASE_DIR/$path" ]] || { echo "${RED}Error:${NC} Directory not found"; return 1; }
    [[ -n "$compose" ]] || { echo "${RED}Error:${NC} No compose file"; return 1; }
    
    cd "$BASE_DIR/$path" || return 1
    
    local cmd="podman-compose -f $(basename "$compose")"
    
    if [[ "$action" == "restart" || "$action" == "down" ]]; then
        if ! is_running "$name"; then
            local status=$(get_status "$name")
            echo "${YELLOW}⚠${NC} $name is ${status}, skipping"
            cd - >/dev/null
            return 0
        fi
    fi
    
    if [[ "$action" == "up" ]] && is_running "$name"; then
        echo "${YELLOW}⚠${NC} $name is already running"
        cd - >/dev/null
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "${YELLOW}[DRY-RUN]${NC} $cmd $action"
        cd - >/dev/null
        return 0
    fi
    
    echo "${BLUE}▶${NC} $name..."
    case $action in
        up)       $cmd up -d ;;
        down)     $cmd down ;;
        restart)  $cmd restart ;;
        pull)     $cmd pull ;;
        logs)     $cmd logs --tail=50; cd - >/dev/null; return 0 ;;
        ps)       $cmd ps; cd - >/dev/null; return 0 ;;
        prune)    podman system prune -f ;;
        recycle)  $cmd pull && $cmd down && $cmd up -d ;;
        update)   $cmd pull && $cmd up -d ;;
        fresh)    $cmd down && $cmd up -d ;;
        *)        echo "${RED}Error:${NC} Unknown action"; cd - >/dev/null; return 1 ;;
    esac
    
    local code=$?
    cd - >/dev/null
    echo "$([[ $code -eq 0 ]] && echo "${GREEN}✓${NC}" || echo "${RED}✗${NC}") $name done"
    return $code
}

main() {
    local action="" services=() run_all=false dry_run=false
    
    [[ $# -eq 0 ]] && { help; exit 0; }
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            help)     help; exit 0 ;;
            version)  version; exit 0 ;;
            list)     list; exit 0 ;;
            all)      run_all=true; shift ;;
            dry-run)  dry_run=true; shift ;;
            up|down|restart|pull|logs|ps|prune|recycle|update|fresh|env)
                action="$1"; shift ;;
            *)  services+=("$1"); shift ;;
        esac
    done
    
    [[ -z "$action" ]] && { help; exit 0; }
    [[ "$dry_run" == true ]] && DRY_RUN=true
    
    echo "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════${NC}"
    echo "${BOLD}${CYAN}  dipen v${VERSION} - Podman Orchestration Tool for Digital Independence   ${NC}"
    echo "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    check || exit 1
    
    if [[ "$action" == "env" ]]; then
        if [[ ${#services[@]} -eq 0 ]]; then
            echo "${RED}Error:${NC} Please specify at least one service"
            echo "${YELLOW}Info:${NC} Usage: dipen env <service1> [service2] [...]"
            echo "${YELLOW}Info:${NC} Examples:"
            echo "  dipen env nextcloud"
            echo "  dipen env nextcloud immich"
            echo "  dipen env n*"
            exit 1
        fi
        
        local expanded_env=()
        for s in "${services[@]}"; do
            for item in $(expand "$s"); do
                local exists=false
                for e in "${expanded_env[@]}"; do
                    [[ "$e" == "$item" ]] && exists=true && break
                done
                [[ "$exists" == false ]] && expanded_env+=("$item")
            done
        done
        
        if [[ ${#expanded_env[@]} -eq 0 ]]; then
            echo "${RED}Error:${NC} No valid services found"
            exit 1
        fi
        
        echo "${BLUE}▶${NC} Editing .env for ${#expanded_env[@]} services: ${CYAN}${expanded_env[*]}${NC}"
        echo
        
        local env_ok=() env_fail=()
        for s in "${expanded_env[@]}"; do
            if [[ -z "${SERVICES[$s]}" ]]; then
                echo "${RED}Error:${NC} Unknown service: $s"
                env_fail+=("$s")
                continue
            fi
            echo "${BOLD}${BLUE}[${#expanded_env[@]}/${#expanded_env[@]}]${NC} Processing $s..."
            edit_env "$s" && env_ok+=("$s") || env_fail+=("$s")
            echo
        done
        
        echo "${BOLD}${CYAN}─────────────────────────────────────────────────────────────────${NC}"
        echo "${GREEN}✓${NC} ${#env_ok[@]} succeeded  ${RED}✗${NC} ${#env_fail[@]} failed"
        [[ ${#env_ok[@]} -gt 0 ]] && echo "  ${GREEN}✓${NC} ${env_ok[*]}"
        [[ ${#env_fail[@]} -gt 0 ]] && echo "  ${RED}✗${NC} ${env_fail[*]}"
        echo
        
        [[ ${#env_fail[@]} -gt 0 ]] && exit 1
        echo "${GREEN}✓${NC} All .env files edited successfully! 🎉"
        echo
        exit 0
    fi
    
    local expanded=()
    if [[ "$run_all" == true ]]; then
        expanded=($(printf '%s\n' "${!SERVICES[@]}" | sort))
        echo "${BLUE}▶${NC} All ${#expanded[@]} services"
    elif [[ ${#services[@]} -eq 0 ]]; then
        echo "${RED}Error:${NC} No service specified"
        echo "${YELLOW}Info:${NC} Use 'list' or 'all'"
        exit 1
    else
        for s in "${services[@]}"; do
            for item in $(expand "$s"); do
                local exists=false
                for e in "${expanded[@]}"; do
                    [[ "$e" == "$item" ]] && exists=true && break
                done
                [[ "$exists" == false ]] && expanded+=("$item")
            done
        done
        echo "${BLUE}▶${NC} ${#expanded[@]} services: ${CYAN}${expanded[*]}${NC}"
    fi
    echo
    
    local total=${#expanded[@]}
    local current=0 ok=() fail=()
    
    for s in "${expanded[@]}"; do
        current=$((current + 1))
        echo "${BOLD}${BLUE}[$current/$total]${NC} Processing $s..."
        
        if [[ -z "${SERVICES[$s]}" ]]; then
            echo "${RED}Error:${NC} Unknown service: $s"
            fail+=("$s")
            echo
            continue
        fi
        
        run "$s" "${SERVICES[$s]}" "$action" && ok+=("$s") || fail+=("$s")
        echo
    done
    
    echo "${BOLD}${CYAN}─────────────────────────────────────────────────────────────────${NC}"
    echo "${GREEN}✓${NC} ${#ok[@]} succeeded  ${RED}✗${NC} ${#fail[@]} failed"
    [[ ${#ok[@]} -gt 0 ]] && echo "  ${GREEN}✓${NC} ${ok[*]}"
    [[ ${#fail[@]} -gt 0 ]] && echo "  ${RED}✗${NC} ${fail[*]}"
    echo
    
    [[ ${#fail[@]} -gt 0 ]] && exit 1
    echo "${GREEN}✓${NC} All done! 🎉"
    echo
}

[[ "$0" != "${BASH_SOURCE[0]}" ]] && return 0
main "$@"