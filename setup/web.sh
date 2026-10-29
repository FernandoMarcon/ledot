#!/bin/bash
# web.sh → pkgs/web.list: browsers, torrents
# Also: Brave + Mozilla repos, browser account logins, Tor Browser
# Usage: bash ~/ledot/setup/web.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ── Brave repo (Brave's installer sets it up and installs the browser) ───────
if ! command -v brave-browser &>/dev/null; then
    info "Setting up Brave browser..."
    curl -fsS https://dl.brave.com/install.sh | sh
fi

# ── Mozilla repo (Ubuntu's firefox is a snap wrapper; snapd is pinned off) ──
if [ ! -f /etc/apt/sources.list.d/mozilla.list ]; then
    sudo install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg \
        | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
        | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
    printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' \
        | sudo tee /etc/apt/preferences.d/mozilla > /dev/null
    sudo apt-get update -qq
    info "Mozilla repo added"
fi

install_list web

# ── Browser accounts (manual) ────────────────────────────────────────────────
header "Browser accounts (Brave)"
echo "  1. proton.me      — log in to ProtonMail / ProtonVPN"
echo "  2. bitwarden.com  — log in"
echo "  3. Gmail          — log in to all Gmail accounts"
echo "  4. Brave Sync     — paste brave://settings/braveSync/setup in the address bar"
echo "  5. Bitwarden extension (Chrome Web Store)"
echo ""
if [ -z "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    warn "No graphical session — do these logins later"
elif confirm "Open Brave with each URL now?"; then
    brave-browser https://proton.me &
    sleep 2; brave-browser https://vault.bitwarden.com &
    sleep 2; brave-browser https://mail.google.com &
    sleep 2; brave-browser "https://chromewebstore.google.com/detail/bitwarden-password-manage/nngceckbapebfimnlniiiahkandclblb?browser=brave" &
    note "Brave windows opened. Complete all logins, then return here."
    confirm "Done with browser logins?" || warn "Finish them later"
fi

# ── Tor Browser ──────────────────────────────────────────────────────────────
header "Tor Browser"
if [ -d "$HOME/.local/share/torbrowser" ] || command -v torbrowser-launcher &>/dev/null; then
    info "Tor Browser already installed — skipping"
elif confirm "Install Tor Browser?"; then
    sudo apt-get install -y torbrowser-launcher
    note "Run torbrowser-launcher once to finish the download."
fi
