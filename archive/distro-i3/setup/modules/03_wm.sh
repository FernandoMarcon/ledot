#!/usr/bin/env bash
## Module 03 – Window manager core
## i3-wm, picom (compositor), dunst (notifications), hsetroot, xsettingsd, polkit, power manager.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "WM Core (i3, picom, dunst, polkit)"

apt_install \
    i3 \
    i3status \
    picom \
    dunst \
    hsetroot \
    xsettingsd \
    xfce4-power-manager \
    policykit-1-gnome

log_ok "WM core packages installed"

# Detect the polkit agent binary and record it for the dotfiles module.
# Ubuntu 24.04 installs polkit-gnome here:
POLKIT_BIN="/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
if [[ ! -x "$POLKIT_BIN" ]]; then
    # Fallback: look for any polkit agent in common locations
    for candidate in \
        /usr/libexec/polkit-gnome-authentication-agent-1 \
        /usr/lib/x86_64-linux-gnu/libexec/polkit-gnome-authentication-agent-1 \
        /usr/lib/xfce4/polkit-gnome-authentication-agent-1; do
        if [[ -x "$candidate" ]]; then
            POLKIT_BIN="$candidate"
            break
        fi
    done
fi

if [[ -x "$POLKIT_BIN" ]]; then
    log_ok "Polkit agent: $POLKIT_BIN"
else
    log_warn "Could not find a polkit agent binary. Privilege dialogs may not work."
fi
