#!/bin/bash
# web.sh → pkgs/web.list: browsers, torrents
# Also: Mozilla repo, browser account logins (Brave, Chromium, Tor Browser: setup/extra.sh)
# Usage: bash ~/ledot/setup/web.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ── Mozilla repo (Ubuntu's firefox is a snap wrapper; snapd is pinned off) ──
if [ ! -f /etc/apt/sources.list.d/mozilla.list ]; then
    sudo install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg \
        | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
        | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
    printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' \
        | sudo tee /etc/apt/preferences.d/mozilla > /dev/null
    apt_update
    info "Mozilla repo added"
fi

# Ubuntu's snap-wrapper deb has epoch 1:, so apt sees Mozilla's deb as a downgrade
if dpkg-query -W -f='${Version}' firefox 2>/dev/null | grep -q snap; then
    info "Replacing Ubuntu's firefox snap wrapper with Mozilla's deb..."
    sudo apt-get install -y --allow-downgrades firefox
    note "Old snap profile: ~/snap/firefox/common/.mozilla (remove snap: sudo snap remove firefox)"
fi

install_list web

# ── Browser accounts (manual) ────────────────────────────────────────────────
header "Browser accounts (Firefox)"
echo "  1. proton.me      — log in to ProtonMail / ProtonVPN"
echo "  2. bitwarden.com  — log in"
echo "  3. Gmail          — log in to all Gmail accounts"
echo "  4. Bitwarden extension (addons.mozilla.org)"
echo ""
if [ -z "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    warn "No graphical session — do these logins later"
elif confirm_no "Open Firefox with each URL now?"; then
    firefox --new-tab https://proton.me \
        --new-tab https://vault.bitwarden.com \
        --new-tab https://mail.google.com \
        --new-tab https://addons.mozilla.org/firefox/addon/bitwarden-password-manager/ &
    note "Firefox opened. Complete all logins, then return here."
    confirm_no "Done with browser logins?" || warn "Finish them later"
fi
