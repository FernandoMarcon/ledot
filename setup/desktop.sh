#!/bin/bash
# Also: Hyprland PPA, Nerd Fonts, Zafiro + Qogir icon/cursor themes, dark mode (GTK + Qt)
# Also: Hyprland PPA, Nerd Fonts, Zafiro + Qogir icon/cursor themes
# Usage: bash ~/ledot/setup/desktop.sh

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
        track_detected "nerd-font:${font}"
        continue
    fi
    info "Installing Nerd Font ${font}..."
    mkdir -p "${fonts_dir}/${font}"
    wget -q "${nf_base}/${font}.zip" -O "/tmp/${font}.zip"
    unzip -q -o "/tmp/${font}.zip" -d "${fonts_dir}/${font}/"
    rm -f "/tmp/${font}.zip"
    track_install "nerd-font:${font}" "github:ryanoasis/nerd-fonts" "${nf_base##*/}"
    fonts_changed=1
done
[ -n "${fonts_changed:-}" ] && fc-cache -f

# ── Icon & cursor themes ─────────────────────────────────────────────────────
icons="${HOME}/.local/share/icons"
mkdir -p "$icons"

if [ -d "${icons}/Zafiro-Icons-Dark" ]; then
    track_detected zafiro-icons
else
    info "Installing Zafiro icon theme..."
    rm -rf /tmp/Zafiro-icons
    git clone -q https://github.com/zayronxio/Zafiro-icons.git /tmp/Zafiro-icons
    cp -r /tmp/Zafiro-icons/Dark  "${icons}/Zafiro-Icons-Dark"
    cp -r /tmp/Zafiro-icons/Light "${icons}/Zafiro-Icons-Light"
    track_install zafiro-icons "git:zayronxio/Zafiro-icons" "$(git -C /tmp/Zafiro-icons rev-parse --short HEAD)"
    rm -rf /tmp/Zafiro-icons
fi

# Qogir cursors live inside Qogir-icon-theme
if [ -d "${icons}/Qogir" ]; then
    track_detected qogir-icons
else
    info "Installing Qogir icon + cursor theme..."
    rm -rf /tmp/Qogir-icon-theme
    git clone -q https://github.com/vinceliuice/Qogir-icon-theme.git /tmp/Qogir-icon-theme
    bash /tmp/Qogir-icon-theme/install.sh
    track_install qogir-icons "git:vinceliuice/Qogir-icon-theme" "$(git -C /tmp/Qogir-icon-theme rev-parse --short HEAD)"
    rm -rf /tmp/Qogir-icon-theme
fi
info "Desktop themes ready"

# ── Dark mode ────────────────────────────────────────────────────────────────
# color-scheme reaches GTK4/libadwaita, browsers and Electron via xdg-desktop-portal-gtk
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
fi

# GTK3/4 apps that read settings.ini instead of gsettings
for v in 3.0 4.0; do
    ini="${HOME}/.config/gtk-${v}/settings.ini"
    if [ -f "$ini" ]; then
        note "${ini} exists — leaving it alone"
        continue
    fi
    mkdir -p "$(dirname "$ini")"
    printf '[Settings]\ngtk-application-prefer-dark-theme=1\ngtk-theme-name=Adwaita-dark\n' > "$ini"
done

# Qt: QT_QPA_PLATFORMTHEME=qt5ct (config/hypr/modules/env.lua) — qt6ct also answers to "qt5ct"
for ct in qt5ct qt6ct; do
    conf="${HOME}/.config/${ct}/${ct}.conf"
    if [ -f "$conf" ]; then
        note "${conf} exists — leaving it alone"
        continue
    fi
    mkdir -p "$(dirname "$conf")"
    printf '[Appearance]\ncolor_scheme_path=/usr/share/%s/colors/darker.conf\ncustom_palette=true\nstyle=Fusion\nicon_theme=Zafiro-Icons-Dark\n' "$ct" > "$conf"
done
info "Dark mode set (GTK + Qt)"
