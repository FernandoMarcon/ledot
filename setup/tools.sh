#!/bin/bash
# tools.sh → pkgs/tools.list: everyday handy tools
# Also: Bitwarden CLI (bw, native binary → ~/.local/bin)
# Usage: bash ~/ledot/setup/tools.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

install_list tools

# ── Bitwarden CLI ────────────────────────────────────────────────────────────
header "Bitwarden CLI"
if command -v bw &>/dev/null; then
    info "Bitwarden CLI already installed — skipping"
    track_detected bitwarden-cli "$(bw --version 2>/dev/null)"
elif confirm "Install Bitwarden CLI (bw)?"; then
    command -v unzip &>/dev/null || sudo apt-get install -y unzip
    tmp=$(mktemp -d)
    curl -fsSL "https://vault.bitwarden.com/download/?app=cli&platform=linux" -o "$tmp/bw.zip"
    unzip -q "$tmp/bw.zip" -d "$tmp"
    install -Dm755 "$tmp/bw" "$HOME/.local/bin/bw"
    rm -rf "$tmp"
    track_install bitwarden-cli "curl:vault.bitwarden.com" "$("$HOME/.local/bin/bw" --version 2>/dev/null)"
    info "Bitwarden CLI installed → ~/.local/bin/bw (login: bw login)"
fi
