#!/usr/bin/env bash
## Module 02 – Xorg & session bootstrap
## Installs the X server, xinit, and configures a startx session for i3.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "Xorg & Session"

# Core X packages
apt_install \
    xorg \
    xinit \
    x11-xserver-utils \
    x11-utils \
    x11-apps \
    xdg-user-dirs \
    dbus-x11

log_ok "Xorg installed"

# Create ~/.xinitrc – tells startx to launch i3
XINITRC="$HOME/.xinitrc"
if [[ ! -f "$XINITRC" ]]; then
    cat > "$XINITRC" <<'EOF'
#!/bin/sh
# Merge Xresources if present
[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"

exec dbus-launch --sh-syntax --exit-with-session i3
EOF
    chmod +x "$XINITRC"
    log_ok "Created ~/.xinitrc"
else
    log_warn "~/.xinitrc already exists – not overwriting"
fi

# Auto-start X on tty1 login (append only if not already there)
PROFILE="$HOME/.bash_profile"
touch "$PROFILE"
if ! grep -q "startx" "$PROFILE"; then
    cat >> "$PROFILE" <<'EOF'

# Auto-start X on tty1
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR:-1}" -eq 1 ]; then
    exec startx
fi
EOF
    log_ok "Auto-startx added to ~/.bash_profile"
else
    log_warn "~/.bash_profile already has startx entry – skipping"
fi

# Ensure XDG dirs exist
xdg-user-dirs-update 2>/dev/null || true

log_ok "X session configured — use 'startx' to launch i3 after setup"
