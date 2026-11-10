#!/bin/bash
# files.sh → pkgs/files.list: file manager previews, archives, file utilities
# Also: yazi (default TUI file manager, .deb from GitHub releases) and
#       ueberzugpp (ranger image previews inside tmux, openSUSE OBS apt repo)
# Usage: bash ~/ledot/setup/files.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ── ueberzugpp repo (home:justkidding on OBS) ────────────────────────────────
UBZ_REPO="https://download.opensuse.org/repositories/home:/justkidding/xUbuntu_$(. /etc/os-release; echo "$VERSION_ID")"
if [ ! -f /etc/apt/sources.list.d/ueberzugpp.list ]; then
    curl -fsSL "${UBZ_REPO}/Release.key" \
        | gpg --dearmor | sudo tee /usr/share/keyrings/ueberzugpp.gpg > /dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/ueberzugpp.gpg] ${UBZ_REPO}/ /" \
        | sudo tee /etc/apt/sources.list.d/ueberzugpp.list > /dev/null
    info "ueberzugpp repo added"
fi

apt_update

# Ubuntu's python `ueberzug` package owns /usr/bin/ueberzug, which ueberzugpp also ships
if dpkg -s ueberzug &>/dev/null; then
    sudo apt-get purge -y ueberzug && info "Removed apt ueberzug (replaced by ueberzugpp)"
fi
install_list files

# The old python ueberzug (pipx) is dead upstream and shadows ueberzugpp's `ueberzug`
if command -v pipx &>/dev/null && pipx list --short 2>/dev/null | grep -q '^ueberzug '; then
    pipx uninstall ueberzug && info "Removed old pipx ueberzug"
fi
track_detected ueberzugpp "$(ueberzugpp --version 2>/dev/null | awk 'NR == 1 { print $2 }')"

# ── yazi ─────────────────────────────────────────────────────────────────────
header "yazi"
latest=$(curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest | jq -r .tag_name)
current=$(yazi --version 2>/dev/null | grep -oEm1 '[0-9]+\.[0-9]+\.[0-9]+' | sed 's/^/v/' || true)
if [ "$current" = "$latest" ]; then
    info "yazi ${latest} already installed — skipping"
    track_detected yazi "${latest#v}"
else
    tmp=$(mktemp -d)
    chmod 755 "$tmp"   # let apt's sandbox user (_apt) read the .deb
    curl -fsSL "https://github.com/sxyazi/yazi/releases/download/${latest}/yazi-x86_64-unknown-linux-gnu.deb" \
        -o "$tmp/yazi.deb"
    sudo apt-get install -y "$tmp/yazi.deb"
    rm -rf "$tmp"
    track_install yazi "github:sxyazi/yazi" "${latest#v}"
    info "yazi ${latest} installed"
fi
