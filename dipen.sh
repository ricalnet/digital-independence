#!/bin/bash

set -o pipefail
set -o errtrace

readonly VERSION="1.1.1"
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
    ["forgejo"]="forgejo"
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

declare -A IMAGE_REGISTRY=(
    ["authentik"]="ghcr.io/goauthentik/server"
    ["dashdot"]="ghcr.io/mauricenino/dashdot"
    ["element-web"]="ghcr.io/element-hq/element-web"
    ["forgejo"]="codeberg.org/forgejo/forgejo"
    ["homarr"]="ghcr.io/homarr-labs/homarr"
    ["immich"]="ghcr.io/immich-app/immich-server"
    ["jellyfin"]="ghcr.io/jellyfin/jellyfin"
    ["libretranslate"]="docker.io/libretranslate/libretranslate"
    ["linkstack"]="docker.io/linkstackorg/linkstack"
    ["mastodon"]="ghcr.io/mastodon/mastodon"
    ["mediawiki"]="docker.io/mediawiki"
    ["navidrome"]="ghcr.io/navidrome/navidrome"
    ["nextcloud"]="docker.io/nextcloud"
    ["ntfy"]="docker.io/binwiederhier/ntfy"
    ["open-webui"]="ghcr.io/open-webui/open-webui"
    ["pi-hole"]="docker.io/pihole/pihole"
    ["portainer"]="docker.io/portainer/portainer-ce"
    ["searxng"]="docker.io/searxng/searxng"
    ["synapse"]="ghcr.io/element-hq/synapse"
    ["synapse-mautrix"]="dock.mau.dev/mautrix/telegram"
    ["uptime-kuma"]="ghcr.io/louislam/uptime-kuma"
    ["vaultwarden"]="ghcr.io/dani-garcia/vaultwarden"
    ["wazuh"]="docker.io/wazuh/wazuh-manager"
    ["yourls"]="docker.io/yourls"
)

declare -A CONTAINER_PATTERNS=(
    ["synapse-mautrix"]="mautrix"
)

help() {
    cat << EOF
${BOLD}dipen v${VERSION} - Podman Orchestration Tool for Digital Independence${NC}
${BOLD}${BLUE}Issues: https://git.ricalnet.my.id/rical/digital-independence/issues ${NC}

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
    check-version       Check latest stable image versions
    cd <service>        Change directory to service directory
    cd volume           Change directory to podman volume directory

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
    dipen check-version
    dipen check-version nextcloud immich
    dipen cd nextcloud
    dipen cd volume
    dipen cd volume nextcloud

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

check_skopeo() {
    command -v skopeo &>/dev/null || { echo "${RED}Error:${NC} skopeo not installed. Install with: apt install skopeo"; return 1; }
    command -v jq &>/dev/null || { echo "${RED}Error:${NC} jq not installed. Install with: apt install jq"; return 1; }
    return 0
}

get_latest_stable_version() {
    local image=$1
    local tags=$(skopeo list-tags "docker://$image" 2>/dev/null | jq -r '.Tags[]' 2>/dev/null)
    
    if [[ -z "$tags" ]]; then
        echo "ERROR"
        return 1
    fi
    
    local version=$(echo "$tags" | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$|^v?[0-9]+\.[0-9]+$' | \
                   sed 's/^v//' | sort -V | tail -1)
    
    if [[ -n "$version" ]]; then
        local original=$(echo "$tags" | grep -E "^v?${version}$" | head -1)
        echo "${original:-$version}"
        return 0
    fi
    
    local latest=$(echo "$tags" | grep -E '^v?latest$' | head -1)
    if [[ -n "$latest" ]]; then
        echo "$latest"
        return 0
    fi
    
    echo "$(echo "$tags" | head -1)"
    return 0
}

check_version() {
    local services=("$@")
    local expanded=()
    
    if [[ ${#services[@]} -eq 0 ]]; then
        expanded=($(printf '%s\n' "${!IMAGE_REGISTRY[@]}" | sort))
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
    fi
    
    check_skopeo || return 1
    
    echo
    echo "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════${NC}"
    echo "${BOLD}${CYAN}              LATEST STABLE IMAGE VERSIONS                                 ${NC}"
    echo "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    local ok=0 fail=0
    
    for s in "${expanded[@]}"; do
        local image="${IMAGE_REGISTRY[$s]}"
        if [[ -z "$image" ]]; then
            printf "${RED}%-25s${NC} | ${RED}%s${NC}\n" "$s" "NO IMAGE"
            ((fail++))
            continue
        fi
        
        local version=$(get_latest_stable_version "$image")
        if [[ "$version" == "ERROR" ]]; then
            printf "${RED}%-25s${NC} | ${RED}%s${NC}\n" "$s" "$image:ERROR"
            ((fail++))
        else
            printf "${GREEN}%-25s${NC} | ${CYAN}%s${NC}\n" "$s" "$image:$version"
            ((ok++))
        fi
    done
    
    echo
    echo "${BOLD}${CYAN}─────────────────────────────────────────────────────────────────${NC}"
    echo "${GREEN}✓${NC} ${ok} succeeded  ${RED}✗${NC} ${fail} failed"
    echo
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

cd_to_service() {
    local name=$1
    local path="${SERVICES[$name]}"
    local target="$BASE_DIR/$path"
    
    if [[ ! -d "$target" ]]; then
        echo "${RED}Error:${NC} Directory not found: $target"
        return 1
    fi
    
    echo "${GREEN}✓${NC} Service directory: $target"
    echo "${YELLOW}Info:${NC} Run the following command to navigate:"
    echo "  cd $target"
    return 0
}

cd_to_volume() {
    local volume_base="$HOME/.local/share/containers/storage/volumes"
    
    if [[ ! -d "$volume_base" ]]; then
        echo "${RED}Error:${NC} Volume directory not found: $volume_base"
        return 1
    fi
    
    echo "${GREEN}✓${NC} Volume directory: $volume_base"
    echo
    echo "${BOLD}${BLUE}Contents:${NC}"
    ls -lh "$volume_base"
    return 0
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
            check-version)
                action="$1"; shift ;;
            up|down|restart|pull|logs|ps|prune|recycle|update|fresh|env|cd)
                action="$1"; shift ;;
            volume)
                if [[ "$action" == "cd" ]]; then
                    action="cd-volume"
                    shift
                else
                    services+=("$1"); shift
                fi
                ;;
            *)  services+=("$1"); shift ;;
        esac
    done
    
    [[ -z "$action" ]] && { help; exit 0; }
    [[ "$dry_run" == true ]] && DRY_RUN=true
    
    echo "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════${NC}"
    echo "${BOLD}${CYAN}  dipen v${VERSION} - Podman Orchestration Tool for Digital Independence   ${NC}"
    echo "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    if [[ "$action" == "check-version" ]]; then
        check || exit 1
        check_version "${services[@]}"
        exit $?
    fi

    if [[ "$action" == "cd-volume" ]]; then
        cd_to_volume
        exit 0
    fi

    if [[ "$action" == "cd" ]]; then
        if [[ ${#services[@]} -eq 0 ]]; then
            echo "${RED}Error:${NC} Please specify at least one service"
            echo "${YELLOW}Info:${NC} Usage: dipen cd <service>"
            exit 1
        fi
        
        local expanded_cd=()
        for s in "${services[@]}"; do
            for item in $(expand "$s"); do
                local exists=false
                for e in "${expanded_cd[@]}"; do
                    [[ "$e" == "$item" ]] && exists=true && break
                done
                [[ "$exists" == false ]] && expanded_cd+=("$item")
            done
        done
        
        local cd_ok=() cd_fail=()
        for s in "${expanded_cd[@]}"; do
            if [[ -z "${SERVICES[$s]}" ]]; then
                echo "${RED}Error:${NC} Unknown service: $s"
                cd_fail+=("$s")
                continue
            fi
            cd_to_service "$s" && cd_ok+=("$s") || cd_fail+=("$s")
        done
        
        [[ ${#cd_fail[@]} -gt 0 ]] && exit 1
        exit 0
    fi

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