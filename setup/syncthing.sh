#!/bin/bash
# syncthing.sh → Syncthing in Docker (config/syncthing/compose.yml) + pair the "Drive" folder with mentat
# Run after: data (it picks where Drive lives and calls this). Standalone: re-uses the layout data.sh saved
# Usage: bash ~/ledot/setup/syncthing.sh [drive-root]   (default: root from ~/.local/state/ledot/data-layout)

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

COMPOSE_DIR="${DOTFILES}/config/syncthing"
ENV_FILE="${LEDOT_STATE}/syncthing.env"     # per-machine compose values (uid, state dir, mount)
LAYOUT_FILE="${LEDOT_STATE}/data-layout"    # written by data.sh: mode=…, root=…
KEYRING="/usr/share/keyrings/syncthing-archive-keyring.gpg"
SOURCES="/etc/apt/sources.list.d/syncthing.list"
VERSIONS_KEEP=5                             # simple file versioning, like carbon

if is_work; then
    info "Work profile — no Syncthing; skipping"
    exit 0
fi
if is_hub; then
    info "${HUB_HOST} is the Syncthing hub (~/stacks/syncthing) — nothing to do here"
    exit 0
fi

DRIVE_ROOT="${1:-$(sed -n 's/^root=//p' "$LAYOUT_FILE" 2>/dev/null)}"
[ -n "$DRIVE_ROOT" ] || die "No drive root — run: install.sh data"
[ -d "$DRIVE_ROOT" ] || die "$DRIVE_ROOT does not exist — run: install.sh data"
command -v docker &>/dev/null || die "docker not found — run: install.sh dev"

# Bind-mount /data when Drive lives under it (keeps the nested folders on carbon working), else Drive itself
if [[ "$DRIVE_ROOT" == /data/* ]]; then SYNC_MOUNT=/data; else SYNC_MOUNT="$DRIVE_ROOT"; fi

st() { docker exec syncthing syncthing cli "$@"; }

# api <METHOD> <path> [json] — local REST API (GUI listens on 127.0.0.1:8384, host network)
api() {
    local key
    key=$(st config gui apikey get)
    curl -fsS -X "$1" -H "X-API-Key: ${key}" -H 'Content-Type: application/json' \
        "http://127.0.0.1:8384/rest/$2" ${3:+--data "$3"}
}

# ── 1. Retire the native (apt + user service) Syncthing — it fights the container for the config lock ──
remove_native() {
    if systemctl --user is-enabled syncthing &>/dev/null || systemctl --user is-active syncthing &>/dev/null; then
        systemctl --user disable --now syncthing || true
        info "Native Syncthing user service disabled"
    fi
    systemctl --user reset-failed syncthing 2>/dev/null || true

    if dpkg -s syncthing &>/dev/null; then
        info "Removing apt syncthing package..."
        sudo apt-get remove -y syncthing
    fi
    if [ -f "$SOURCES" ]; then
        sudo rm -f "$SOURCES" "$KEYRING"
        info "Syncthing apt repo removed"
    fi
}

# ── 2. Run the container ──────────────────────────────────────────────────────
start_container() {
    local state="${XDG_STATE_HOME:-${HOME}/.local/state}/syncthing"
    mkdir -p "$state" "$LEDOT_STATE"
    printf 'PUID=%s\nPGID=%s\nSYNCTHING_STATE=%s\nSYNC_MOUNT=%s\n' \
        "$(id -u)" "$(id -g)" "$state" "$SYNC_MOUNT" > "$ENV_FILE"

    info "Starting Syncthing container (mount: ${SYNC_MOUNT})..."
    docker compose --project-directory "$COMPOSE_DIR" --env-file "$ENV_FILE" up -d

    for _ in $(seq 30); do
        st show system &>/dev/null && { info "Syncthing container running (restart: unless-stopped)"; return 0; }
        sleep 1
    done
    die "Syncthing didn't come up — docker logs syncthing"
}

# ── 3. Pair Drive with mentat: each side adds the other device; Drive shared both ways ──
pair_with_hub() {
    local my_id hub_id
    my_id=$(st show system | sed -n 's/.*"myID": *"\([^"]*\)".*/\1/p')

    if ! ensure_hub_ssh; then
        warn "Can't reach ${HUB_HOST} over ssh — pair by hand:"
        note "on ${HUB_HOST}'s GUI: add device ${my_id}, share the 'Drive' folder with it"
        note "here (http://localhost:8384): accept ${HUB_HOST} and the 'Drive' folder at ${DRIVE_ROOT}"
        return 0
    fi

    hub_id=$(hub_ssh "$HUB_ST_CLI show system" | sed -n 's/.*"myID": *"\([^"]*\)".*/\1/p')
    [ -n "$hub_id" ] || die "Couldn't read ${HUB_HOST}'s Syncthing device ID"

    # mentat: know this device, share Drive with it
    if hub_ssh "$HUB_ST_CLI config devices list" | grep -qx "$my_id"; then
        info "${HUB_HOST} already knows $(hostname)"
    else
        hub_ssh "$HUB_ST_CLI config devices add --device-id $my_id --name $(hostname)"
        info "${HUB_HOST}: added device $(hostname)"
    fi
    if hub_ssh "$HUB_ST_CLI config folders $HUB_FOLDER_ID devices list" | grep -qx "$my_id"; then
        info "${HUB_HOST}: Drive already shared with $(hostname)"
    else
        hub_ssh "$HUB_ST_CLI config folders $HUB_FOLDER_ID devices add --device-id $my_id"
        info "${HUB_HOST}: Drive shared with $(hostname)"
    fi

    # here: know mentat, have Drive at $DRIVE_ROOT with simple versioning
    st config devices list | grep -qx "$hub_id" \
        || { st config devices add --device-id "$hub_id" --name "$HUB_HOST"; info "Added device ${HUB_HOST}"; }

    local versioning="{\"type\":\"simple\",\"params\":{\"keep\":\"${VERSIONS_KEEP}\",\"cleanoutDays\":\"0\"}}"
    if st config folders list | grep -qx "$HUB_FOLDER_ID"; then
        api PATCH "config/folders/${HUB_FOLDER_ID}" "{\"path\":\"${DRIVE_ROOT}\",\"versioning\":${versioning}}" >/dev/null
        st config folders "$HUB_FOLDER_ID" devices list | grep -qx "$hub_id" \
            || st config folders "$HUB_FOLDER_ID" devices add --device-id "$hub_id"
        info "Drive folder: ${DRIVE_ROOT} (updated)"
    else
        api POST "config/folders" "{\"id\":\"${HUB_FOLDER_ID}\",\"label\":\"Drive\",\"path\":\"${DRIVE_ROOT}\",
            \"type\":\"sendreceive\",\"devices\":[{\"deviceID\":\"${my_id}\"},{\"deviceID\":\"${hub_id}\"}],
            \"versioning\":${versioning}}" >/dev/null
        info "Drive folder added: ${DRIVE_ROOT} ⇄ ${HUB_HOST}:${HUB_DRIVE} (simple versioning, keep ${VERSIONS_KEEP})"
    fi
}

# ── 4. Show status ────────────────────────────────────────────────────────────
show_info() {
    echo ""
    info "Syncthing setup complete!"
    echo ""
    echo -e "  Web UI:      ${GREEN}http://localhost:8384${RESET}"
    echo -e "  Device ID:   ${YELLOW}$(docker exec syncthing syncthing device-id 2>/dev/null || echo unavailable)${RESET}"
    echo -e "  Drive:       ${DRIVE_ROOT} ⇄ ${HUB_HOST}:${HUB_DRIVE}"
    echo ""
    info "To manage the container:"
    echo "     docker compose --project-directory ${COMPOSE_DIR} --env-file ${ENV_FILE} ps"
    echo "     docker logs -f syncthing"
}

# ── Run ───────────────────────────────────────────────────────────────────────
remove_native
start_container
pair_with_hub
show_info
