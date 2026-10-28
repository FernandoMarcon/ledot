#!/usr/bin/env bash
## Module 11 – Networking
## NetworkManager, nm-applet (tray), and networkmanager-dmenu (rofi network menu).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "Networking"

apt_install \
    network-manager \
    network-manager-gnome \
    network-manager-openvpn \
    bluez \
    bluez-tools \
    blueman

# Ensure NetworkManager is enabled (server installs may prefer systemd-networkd)
sudo systemctl enable --now NetworkManager 2>/dev/null || true
log_ok "NetworkManager enabled"

# ── networkmanager-dmenu ─────────────────────────────────────────────────────
# A rofi/dmenu front-end for NetworkManager (used by rofi_networks / network_menu script).
NM_DMENU_BIN="/usr/local/bin/networkmanager_dmenu"
if [[ -x "$NM_DMENU_BIN" ]]; then
    log_ok "networkmanager-dmenu already installed"
else
    log_info "Installing networkmanager-dmenu..."
    apt_install python3-gi gir1.2-nm-1.0

    TMP=$(mktemp -d)
    git clone --depth=1 https://github.com/firecat53/networkmanager-dmenu "$TMP/nm-dmenu"

    # Install the single-file script
    sudo install -Dm755 "$TMP/nm-dmenu/networkmanager_dmenu" "$NM_DMENU_BIN"

    # Default config (uses rofi)
    NM_DMENU_CFG="$HOME/.config/networkmanager-dmenu/config.ini"
    mkdir -p "$(dirname "$NM_DMENU_CFG")"
    if [[ ! -f "$NM_DMENU_CFG" ]]; then
        cat > "$NM_DMENU_CFG" <<'EOF'
[dmenu]
dmenu_command = rofi -dmenu

[editor]
terminal = alacritty
EOF
    fi

    rm -rf "$TMP"
    log_ok "networkmanager-dmenu installed"
fi
