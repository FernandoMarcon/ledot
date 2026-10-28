#!/bin/bash
# polybar-config.sh — polybar step extracted from distro/04.manual-setup (archived with the i3 setup)
DOTFILES="$HOME/.dotfiles"
source "$DOTFILES/setup/lib/common.sh"
# 10. POLYBAR CONFIG — partial
# =============================================================================
header "10/10  Polybar Config  [partial]"
note "Copies hardware-aware polybar files from distro and updates fonts."
echo ""

POLYBAR_SRC="${DOTFILES}/archive/distro-i3/archcraft-i3wm/files/theme/polybar"
POLYBAR_DST="${DOTFILES}/polybar"

if [ ! -d "${POLYBAR_SRC}" ]; then
    warn "Source not found: ${POLYBAR_SRC} — skipping"
else
    echo "  Files to copy from distro:"
    echo "    launch.sh  modules.ini  colors.ini  decor.ini  → ${POLYBAR_DST}/"
    echo ""
    echo "  Font config to apply to polybar/config:"
    echo "    font-0 = JetBrainsMono Nerd Font:bold:size=10;3"
    echo "    font-1 = Symbols Nerd Font Mono:size=12;3"
    echo "    font-2 = Symbols Nerd Font Mono:size=20;4"
    echo "    font-3 = Iosevka Nerd Font:bold:size=12;4"
    echo ""
    if confirm "Apply polybar config now?"; then
        for f in launch.sh modules.ini colors.ini decor.ini; do
            if [ -f "${POLYBAR_SRC}/${f}" ]; then
                cp "${POLYBAR_SRC}/${f}" "${POLYBAR_DST}/${f}"
                info "Copied ${f}"
            else
                warn "${f} not found in source — skipping"
            fi
        done
        CONFIG="${POLYBAR_DST}/config"
        if [ -f "${CONFIG}" ]; then
            sed -i 's/^font-0\s*=.*/font-0 = JetBrainsMono Nerd Font:bold:size=10;3/' "${CONFIG}"
            sed -i 's/^font-1\s*=.*/font-1 = Symbols Nerd Font Mono:size=12;3/'       "${CONFIG}"
            sed -i 's/^font-2\s*=.*/font-2 = Symbols Nerd Font Mono:size=20;4/'       "${CONFIG}"
            sed -i 's/^font-3\s*=.*/font-3 = Iosevka Nerd Font:bold:size=12;4/'       "${CONFIG}"
            info "Font config updated in polybar/config"
        else
            warn "polybar/config not found — font lines not updated"
        fi
    fi
fi

