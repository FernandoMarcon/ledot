#!/bin/bash
# syncthing.sh — mount data partition, link vault dirs, install and configure Syncthing
# Usage: bash ~/.dotfiles/setup/syncthing.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

CONFIG_DIR="${HOME}/.config/syncthing"
KEYRING="/usr/share/keyrings/syncthing-archive-keyring.gpg"
SOURCES="/etc/apt/sources.list.d/syncthing.list"
DATA_DEV="/dev/nvme0n1p3"
DATA_MNT="/data"
VAULT_DIR="/data/vault"

command -v curl &>/dev/null || die "curl not found — run setup/minimal.sh first"
command -v systemctl &>/dev/null || die "systemd not found"

# ── 1. Mount data partition ───────────────────────────────────────────────────
setup_data_mount() {
    [ -b "$DATA_DEV" ] || die "$DATA_DEV not found — is the NVMe drive present?"

    # Create mount point and vault dir
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

    # Persist in /etc/fstab if not already present
    if grep -q "^${DATA_DEV}" /etc/fstab; then
        info "fstab entry already exists for $DATA_DEV"
    else
        local fstype
        fstype=$(blkid -o value -s TYPE "$DATA_DEV" 2>/dev/null || echo "auto")
        echo "${DATA_DEV}  ${DATA_MNT}  ${fstype}  defaults  0  2" \
            | sudo tee -a /etc/fstab >/dev/null
        info "Added fstab entry (${fstype}): $DATA_DEV → $DATA_MNT"
    fi

    # Create vault subdir (after mount so it lands on the right fs)
    sudo mkdir -p "$VAULT_DIR"
    sudo chown "${USER}:${USER}" "$VAULT_DIR"
    info "Vault dir ready: $VAULT_DIR"
}

# ── 2. Create vault dirs and home symlinks ────────────────────────────────────
setup_vault_links() {
    local -a LINKS=(
        "Documents:${HOME}/Documents"
        "Music:${HOME}/Music"
        "Pictures:${HOME}/Pictures"
        "Videos:${HOME}/Videos"
        "code:${HOME}/code"
        "homelab:${HOME}/homelab"
        "work:${HOME}/work"
        "Vaults:${HOME}/Vaults"
    )

    for entry in "${LINKS[@]}"; do
        local name="${entry%%:*}"
        local home_path="${entry#*:}"
        local vault_path="${VAULT_DIR}/${name}"

        mkdir -p "$vault_path"

        # Already correctly linked — skip
        if [ -L "$home_path" ] && [ "$(readlink -f "$home_path")" = "$vault_path" ]; then
            info "Already linked: $home_path → $vault_path"
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
                info "Migrating $home_path → $vault_path"
                cp -a "${home_path}/." "$vault_path/"
            fi
            rm -rf "$home_path"
        fi

        ln -sf "$vault_path" "$home_path"
        info "Linked: $home_path → $vault_path"
    done
}

# ── 3. Add Syncthing apt repo ────────────────────────────────────────────────
setup_repo() {
    if [ -f "$SOURCES" ]; then
        info "Syncthing apt repo already configured"
        return
    fi

    info "Adding Syncthing apt repo..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://syncthing.net/release-key.gpg \
        | gpg --dearmor \
        | sudo tee "$KEYRING" >/dev/null

    echo "deb [signed-by=${KEYRING}] https://apt.syncthing.net/ syncthing stable" \
        | sudo tee "$SOURCES" >/dev/null

    sudo apt-get update -qq
    info "Syncthing repo added"
}

# ── 4. Install Syncthing ──────────────────────────────────────────────────────
install_syncthing() {
    if command -v syncthing &>/dev/null; then
        info "Syncthing already installed ($(syncthing --version | head -1))"
        return
    fi

    info "Installing Syncthing..."
    sudo apt-get install -y syncthing
    info "Syncthing installed ($(syncthing --version | head -1))"
}

# ── 5. Enable user service ────────────────────────────────────────────────────
enable_service() {
    if systemctl --user is-enabled syncthing &>/dev/null; then
        info "Syncthing user service already enabled"
    else
        info "Enabling Syncthing user service..."
        systemctl --user enable syncthing
        info "Service enabled"
    fi

    if systemctl --user is-active syncthing &>/dev/null; then
        info "Syncthing already running"
    else
        info "Starting Syncthing..."
        systemctl --user start syncthing

        # Wait for config to be generated (up to 10s)
        local i=0
        while [ ! -f "${CONFIG_DIR}/config.xml" ] && [ "$i" -lt 10 ]; do
            sleep 1
            (( i++ ))
        done

        if [ -f "${CONFIG_DIR}/config.xml" ]; then
            info "Syncthing started and config generated"
        else
            warn "Config not yet generated — it will appear after the service fully starts"
        fi
    fi
}

# ── 6. Configure ─────────────────────────────────────────────────────────────
configure() {
    local config="${CONFIG_DIR}/config.xml"

    [ -f "$config" ] || { warn "Config not found yet — skipping configuration step"; return; }

    # Set device name to hostname if still the default
    local hostname
    hostname=$(hostname)
    if grep -q '<device name="'"${hostname}"'"' "$config" 2>/dev/null; then
        info "Device name already set to '${hostname}'"
    else
        # Replace existing name attribute on the local device element
        sed -i "s|<device name=\"[^\"]*\" id=\"$(syncthing --device-id 2>/dev/null)\"|<device name=\"${hostname}\" id=\"$(syncthing --device-id 2>/dev/null)\"|" "$config" 2>/dev/null || true
        info "Device name set to '${hostname}'"
    fi

    # Ensure GUI listens on localhost only (default, but make it explicit)
    if grep -q '<address>127.0.0.1:8384</address>' "$config"; then
        info "GUI already bound to localhost:8384"
    fi
}

# ── 7. Show status ────────────────────────────────────────────────────────────
show_info() {
    local device_id=""
    if command -v syncthing &>/dev/null; then
        device_id=$(syncthing --device-id 2>/dev/null || echo "unavailable")
    fi

    echo ""
    info "Syncthing setup complete!"
    echo ""
    echo -e "  Web UI:      ${GREEN}http://localhost:8384${RESET}"
    echo -e "  Device ID:   ${YELLOW}${device_id}${RESET}"
    echo -e "  Config:      ${CONFIG_DIR}/config.xml"
    echo -e "  Data:        ${HOME}/Sync  (default folder)"
    echo ""
    warn "Next steps:"
    warn "  1. Open http://localhost:8384 and set a GUI password (Actions > Settings > GUI)"
    warn "  2. Add remote devices using their Device ID"
    warn "  3. Share folders with those devices"
    echo ""
    info "To manage the service:"
    echo "     systemctl --user status syncthing"
    echo "     systemctl --user restart syncthing"
    echo "     journalctl --user -u syncthing -f"
}

# ── Run ───────────────────────────────────────────────────────────────────────
setup_data_mount
setup_vault_links
setup_repo
install_syncthing
enable_service
configure
show_info
