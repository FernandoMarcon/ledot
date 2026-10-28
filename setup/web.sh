#!/bin/bash
# web.sh — pkgs/web.list: browsers, torrents
# Also: Brave repo, browser account logins, Tor Browser, brotab
# Usage: bash ~/ledot/setup/web.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ── Brave repo (Brave's installer sets it up and installs the browser) ───────
if ! command -v brave-browser &>/dev/null; then
    info "Setting up Brave browser..."
    curl -fsS https://dl.brave.com/install.sh | sh
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

# ── brotab (browser tab CLI) ─────────────────────────────────────────────────
# pipx keeps it isolated from conda dependency conflicts
pipx_install brotab
note "brotab needs its browser extension:"
note "  Chrome/Brave: https://chrome.google.com/webstore/detail/brotab/mhpeahbikehnfkfnmopaigggliclhmnc"
note "  Firefox:      https://addons.mozilla.org/en-US/firefox/addon/brotab/"
