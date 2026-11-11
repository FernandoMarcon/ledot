#!/bin/bash
# apps.sh → pkgs/apps.list + apps.flatpak: office, remote desktop, file manager, Proton (+ GNOME tray extension), LocalSend
# Also: FUTO Notes repo, Thunar as default folder handler
# Usage: bash ~/ledot/setup/apps.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ── FUTO Notes repo ──────────────────────────────────────────────────────────
if [ ! -f /etc/apt/sources.list.d/futo-notes.list ]; then
    curl -fsSL https://pkg.futoinfra.com/futo-archive-key.gpg \
        | sudo tee /usr/share/keyrings/futo-archive.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/futo-archive.gpg] https://pkg.futoinfra.com/futo-notes stable main" \
        | sudo tee /etc/apt/sources.list.d/futo-notes.list > /dev/null
    info "FUTO Notes repo added"
fi

apt_update
install_list apps
sudo apt-get install -y futo-notes
install_flatpaks apps

# ── Proton VPN system tray (GNOME: AppIndicator extension) ───────────────────
if command -v gnome-extensions &>/dev/null; then
    gnome-extensions enable ubuntu-appindicators@ubuntu.com 2>/dev/null \
        && info "AppIndicator extension enabled (Proton VPN tray icon)" \
        || note "Enable AppIndicator in Extensions (gnome-extensions-app) from a GNOME session"
fi

# ── Thunar opens folders (mod+E stays yazi) ────────────────────────────────
xdg-mime default thunar.desktop inode/directory
info "Thunar set as default folder handler"
