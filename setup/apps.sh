#!/bin/bash
# apps.sh — pkgs/apps.list + apps.flatpak: office, remote desktop, file manager, Proton, LocalSend, FreeCAD
# Also: FUTO Notes repo, Thunar as default folder handler
# Usage: bash ~/ledot/setup/apps.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ── FUTO Notes repo ──────────────────────────────────────────────────────────
if [ ! -f /etc/apt/sources.list.d/futo-notes.list ]; then
    curl -fsSL https://pkg.futoinfra.com/futo-archive-key.gpg \
        | sudo tee /usr/share/keyrings/futo-archive.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/futo-archive.gpg] https://pkg.futoinfra.com/futo-notes stable main" \
        | sudo tee /etc/apt/sources.list.d/futo-notes.list > /dev/null
    info "FUTO Notes repo added"
fi

sudo apt-get update -qq
install_list apps
sudo apt-get install -y futo-notes
install_flatpaks apps

# ── Thunar opens folders (mod+E stays ranger) ────────────────────────────────
xdg-mime default thunar.desktop inode/directory
info "Thunar set as default folder handler"
