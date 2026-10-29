#!/bin/bash
# syncthing.sh → mount data partition, link ~/<dir> → /data/drive/<dir>, run Syncthing in Docker (config/syncthing/compose.yml)
# Usage: bash ~/ledot/setup/syncthing.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

COMPOSE_DIR="${DOTFILES}/config/syncthing"   # compose.yml + .env (PUID, PGID, SYNCTHING_STATE)
KEYRING="/usr/share/keyrings/syncthing-archive-keyring.gpg"
SOURCES="/etc/apt/sources.list.d/syncthing.list"
DATA_DEV="/dev/nvme0n1p3"
DATA_MNT="/data"
DRIVE_DIR="/data/drive"   # synced as one Syncthing folder ("Drive")

command -v curl &>/dev/null || die "curl not found — run setup/minimal.sh first"
command -v systemctl &>/dev/null || die "systemd not found"
command -v docker &>/dev/null || die "docker not found — run setup/dev.sh first"

# ── 1. Mount data partition ───────────────────────────────────────────────────
setup_data_mount() {
    [ -b "$DATA_DEV" ] || die "$DATA_DEV not found — is the NVMe drive present?"

    # Create mount point
    sudo mkdir -p "$DATA_MNT"
    info "Mount point $DATA_MNT ready"

    # Mount if not already mounted
    if mountpoint -q "$DATA_MNT"; then
        info "$DATA_DEV already mounted at $DATA_MNT"
    else
        info "Mounting $DATA_DEV at $DATA_MNT..."
        sudo mount "$DATA_DEV" "$DATA_MNT"
        info "Mounted $DATA_DEV → $DATA_MNT"
    fi

    # Drop a bare-device duplicate of an existing /data entry (older runs of this script added one)
    if [ "$(findmnt --fstab -n -o TARGET "$DATA_MNT" | wc -l)" -gt 1 ] && grep -q "^${DATA_DEV}[[:space:]]" /etc/fstab; then
        sudo sed -i "\\|^${DATA_DEV}[[:space:]]|d" /etc/fstab
        warn "Removed duplicate fstab entry for $DATA_DEV"
    fi

    # Persist in /etc/fstab (by UUID) if not already present
    if findmnt --fstab -n "$DATA_MNT" &>/dev/null; then
        info "fstab entry already exists for $DATA_MNT"
    else
        local uuid fstype
        uuid=$(sudo blkid -o value -s UUID "$DATA_DEV")
        fstype=$(sudo blkid -o value -s TYPE "$DATA_DEV")
        [ -n "$uuid" ] && [ -n "$fstype" ] || die "Could not read UUID/filesystem of $DATA_DEV"
        echo "UUID=${uuid}  ${DATA_MNT}  ${fstype}  defaults,nofail  0  2" \
            | sudo tee -a /etc/fstab >/dev/null
        info "Added fstab entry (${fstype}): UUID=${uuid} → $DATA_MNT"
    fi

    # Create drive dir (after mount so it lands on the right fs)
    sudo mkdir -p "$DRIVE_DIR"
    sudo chown "${USER}:${USER}" "$DRIVE_DIR"
    info "Drive dir ready: $DRIVE_DIR"
}

# ── 2. Create drive dirs and home symlinks (~/<dir> → /data/drive/<dir>) ─────
setup_drive_links() {
    local -a DIRS=(Audio Cursos Data Documents Images Projects Vaults Videos Work dockers utils)

    for name in "${DIRS[@]}"; do
        local home_path="${HOME}/${name}"
        local drive_path="${DRIVE_DIR}/${name}"

        mkdir -p "$drive_path"

        # Already correctly linked — skip
        if [ -L "$home_path" ] && [ "$(readlink -f "$home_path")" = "$drive_path" ]; then
            info "Already linked: $home_path → $drive_path"
            continue
        fi

        # Symlink pointing somewhere else — warn and skip
        if [ -L "$home_path" ]; then
            warn "Skipping $home_path — already a symlink to $(readlink "$home_path")"
            continue
        fi

        # Real directory — migrate existing contents then replace with symlink
        if [ -d "$home_path" ]; then
            if [ -n "$(ls -A "$home_path" 2>/dev/null)" ]; then
                info "Migrating $home_path → $drive_path"
                cp -a "${home_path}/." "$drive_path/"
            fi
            rm -rf "$home_path"
        fi

        ln -sf "$drive_path" "$home_path"
        info "Linked: $home_path → $drive_path"
    done

    # homelab lives inside Projects
    mkdir -p "${DRIVE_DIR}/Projects/homelab"
}

# ── 3. Retire the native (apt + user service) Syncthing — it fights the container for the config lock ──
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

# ── 4. Run the container ──────────────────────────────────────────────────────
start_container() {
    local state
    state=$(sed -n 's/^SYNCTHING_STATE=//p' "${COMPOSE_DIR}/.env")
    mkdir -p "$state"

    info "Starting Syncthing container..."
    docker compose --project-directory "$COMPOSE_DIR" up -d
    info "Syncthing container running (restart: unless-stopped)"
}

# ── 5. Show status ────────────────────────────────────────────────────────────
show_info() {
    local device_id
    device_id=$(docker exec syncthing syncthing device-id 2>/dev/null || echo "unavailable (container still starting?)")

    echo ""
    info "Syncthing setup complete!"
    echo ""
    echo -e "  Web UI:      ${GREEN}http://localhost:8384${RESET}"
    echo -e "  Device ID:   ${YELLOW}${device_id}${RESET}"
    echo -e "  Compose:     ${COMPOSE_DIR}/compose.yml"
    echo ""
    info "To manage the container:"
    echo "     docker compose --project-directory ${COMPOSE_DIR} ps"
    echo "     docker restart syncthing"
    echo "     docker logs -f syncthing"
}

# ── Run ───────────────────────────────────────────────────────────────────────
setup_data_mount
setup_drive_links
remove_native
start_container
show_info
