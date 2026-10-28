#!/usr/bin/env bash
## Module 06 – Fonts
## Installs JetBrainsMono, Symbols Only, and Iosevka Nerd Fonts.
## These are required by the i3 theme (window titles) and Polybar modules.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "Nerd Fonts"

# System font packages available in Ubuntu 24.04 universe
apt_install fonts-jetbrains-mono curl unzip fontconfig

FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
mkdir -p "$FONT_DIR"

# ── Helper: download a Nerd Font zip and extract OTF/TTF to FONT_DIR ─────────
install_nerd_font() {
    local font_name="$1"    # e.g. "JetBrainsMono"
    local check_file="$2"   # a file that proves the font is installed

    if fc-list | grep -qi "$check_file"; then
        log_ok "$font_name Nerd Font already installed"
        return
    fi

    log_info "Downloading $font_name Nerd Font..."

    # Resolve the latest release tag from GitHub
    local api_url="https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
    local tag
    tag=$(curl -sf "$api_url" | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$tag" ]]; then
        log_warn "Could not fetch nerd-fonts release tag. Skipping $font_name."
        return
    fi

    local zip_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${tag}/${font_name}.zip"
    local tmp_zip
    tmp_zip=$(mktemp /tmp/nf_XXXXXX.zip)

    if curl -fsSL -o "$tmp_zip" "$zip_url"; then
        unzip -o -j "$tmp_zip" '*.ttf' '*.otf' -d "$FONT_DIR" 2>/dev/null || true
        rm -f "$tmp_zip"
        log_ok "$font_name Nerd Font installed"
    else
        rm -f "$tmp_zip"
        log_warn "Failed to download $font_name Nerd Font. Download manually from the nerd-fonts releases."
    fi
}

install_nerd_font "JetBrainsMono"   "JetBrainsMono Nerd"
install_nerd_font "NerdFontsSymbolsOnly" "Symbols Nerd Font"
install_nerd_font "Iosevka"         "Iosevka Nerd"

# Rebuild font cache
fc-cache -f "$FONT_DIR"
log_ok "Font cache rebuilt"

# ── Archcraft icon font (used by Polybar menu button, font-4) ────────────────
# This small font provides the archcraft logo glyph.
# Without it the menu module shows a box — everything else still works.
ARCHCRAFT_FONT="$FONT_DIR/archcraft.ttf"
if [[ ! -f "$ARCHCRAFT_FONT" ]]; then
    log_info "Attempting to download the archcraft icon font..."
    ARCH_FONT_URL="https://github.com/archcraft-os/archcraft-fonts/raw/main/fonts/archcraft.ttf"
    if curl -fsSL -o "$ARCHCRAFT_FONT" "$ARCH_FONT_URL" 2>/dev/null; then
        fc-cache -f "$FONT_DIR"
        log_ok "archcraft icon font installed"
    else
        log_warn "Could not download archcraft font. The polybar menu icon will show a box glyph."
        log_warn "You can install it manually: copy archcraft.ttf to $FONT_DIR and run fc-cache -f"
    fi
fi
