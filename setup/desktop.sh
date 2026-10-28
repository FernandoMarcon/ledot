#!/bin/bash
# desktop.sh — pkgs/desktop.list: Hyprland session, launcher, terminals, fonts
# Also: Hyprland PPA, Nerd Fonts, Zafiro + Qogir icon/cursor themes
# Usage: bash ~/.dotfiles/setup/desktop.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ── Hyprland PPA ─────────────────────────────────────────────────────────────
if ! grep -rq "ppa.launchpadcontent.net/cppiber/hyprland" /etc/apt/sources.list.d/ 2>/dev/null; then
    command -v add-apt-repository &>/dev/null || sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:cppiber/hyprland
    info "Hyprland PPA added"
fi

sudo apt-get update -qq
install_list desktop

# ── Nerd Fonts ───────────────────────────────────────────────────────────────
fonts_dir="${HOME}/.local/share/fonts"
nf_base="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1"
for font in JetBrainsMono NerdFontsSymbolsOnly Iosevka; do
    if [ -d "${fonts_dir}/${font}" ]; then
        info "Nerd Font ${font} already installed"
        continue
    fi
    info "Installing Nerd Font ${font}..."
    mkdir -p "${fonts_dir}/${font}"
    wget -q "${nf_base}/${font}.zip" -O "/tmp/${font}.zip"
    unzip -q -o "/tmp/${font}.zip" -d "${fonts_dir}/${font}/"
    rm -f "/tmp/${font}.zip"
    fonts_changed=1
done
[ -n "${fonts_changed:-}" ] && fc-cache -f

# ── Icon & cursor themes ─────────────────────────────────────────────────────
icons="${HOME}/.local/share/icons"
mkdir -p "$icons"

if [ ! -d "${icons}/Zafiro-Icons-Dark" ]; then
    info "Installing Zafiro icon theme..."
    rm -rf /tmp/Zafiro-icons
    git clone -q https://github.com/zayronxio/Zafiro-icons.git /tmp/Zafiro-icons
    cp -r /tmp/Zafiro-icons/Dark  "${icons}/Zafiro-Icons-Dark"
    cp -r /tmp/Zafiro-icons/Light "${icons}/Zafiro-Icons-Light"
    rm -rf /tmp/Zafiro-icons
fi

# Qogir cursors live inside Qogir-icon-theme
if [ ! -d "${icons}/Qogir" ]; then
    info "Installing Qogir icon + cursor theme..."
    rm -rf /tmp/Qogir-icon-theme
    git clone -q https://github.com/vinceliuice/Qogir-icon-theme.git /tmp/Qogir-icon-theme
    bash /tmp/Qogir-icon-theme/install.sh
    rm -rf /tmp/Qogir-icon-theme
fi
info "Desktop themes ready"
