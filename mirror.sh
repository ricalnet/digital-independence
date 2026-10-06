#!/usr/bin/env bash

set -euo pipefail

TAG="${TAG:-stable}"              # Default target tag
TLS_VERIFY="${TLS_VERIFY:-false}" # TLS verification for target registry
CLEANUP="${CLEANUP:-true}"        # Remove source images after push
SKIP_LOGIN="${SKIP_LOGIN:-false}" # Skip initial podman login

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
log()  { echo -e "${G}[+]${N} $*"; }
warn() { echo -e "${Y}[!]${N} $*"; }
err()  { echo -e "${R}[x]${N} $*" >&2; }

show_help() {
    cat <<'EOF'
mirror.sh - Mirror container images between registries.

USAGE:
    ./mirror.sh <target-registry> <list-file> [--help]

ARGS:
    <target-registry>   Target registry with namespace.
                        Example: 127.0.0.1:3002/rical
                                 git.ricalnet.my.id/rical
    <list-file>         File listing images, one per line:
                            <source-image> <target-name> [target-tag]
                        Lines starting with '#' and blank lines are ignored.

ENV:
    TAG=stable          Default target tag.
    TLS_VERIFY=false    Enable TLS verification.
    CLEANUP=true        Remove source images after push.
    SKIP_LOGIN=false    Skip initial 'podman login'.

EXAMPLES:
    ./mirror.sh 127.0.0.1:3002/rical images.txt
    ./mirror.sh git.ricalnet.my.id/rical images.txt
    TLS_VERIFY=true ./mirror.sh registry.example.com/myteam images.txt
    CLEANUP=false   ./mirror.sh 127.0.0.1:3002/rical images.txt
    TAG=v1.0        ./mirror.sh 127.0.0.1:3002/rical images.txt
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

if [[ $# -lt 2 ]]; then
    err "Usage: $0 <target-registry> <list-file>"
    err "Run '$0 --help' for details."
    exit 1
fi

REGISTRY="$1"
LIST="$2"

if [[ ! -f "$LIST" ]]; then
    err "List file not found: $LIST"
    exit 1
fi

if [[ "$SKIP_LOGIN" == "true" ]]; then
    warn "Skipping login (SKIP_LOGIN=true)"
else
    log "Logging in to $REGISTRY"
    if ! podman login --tls-verify="$TLS_VERIFY" "$REGISTRY"; then
        warn "Login failed or was skipped."
        warn "Continuing anyway — push may fail if authentication is required."
    fi
fi

ok=0
fail=0

while read -r src dst tag; do
    [[ -z "${src:-}" || "$src" == \#* ]] && continue

    target="${REGISTRY}/${dst}:${tag:-$TAG}"

    echo
    log "Processing: $src  ->  $target"

    if podman pull "$src" \
       && podman tag "$src" "$target" \
       && podman push --tls-verify="$TLS_VERIFY" "$target"; then
        log "Pushed: $target"
        ok=$((ok + 1))

        if [[ "$CLEANUP" == "true" ]]; then
            log "Removing source: $src"
            podman rmi "$src" || warn "Could not remove $src (may still be in use)"
        fi
    else
        err "Failed: $src"
        fail=$((fail + 1))
    fi
done < "$LIST"

echo
log "Cleaning up dangling images..."
podman image prune -f >/dev/null 2>&1 || true

echo
log "Summary: $ok succeeded, $fail failed."

if [[ $fail -gt 0 ]]; then
    exit 2
fi

log "All done."
exit 0