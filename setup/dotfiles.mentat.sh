#!/bin/bash
# dotfiles.mentat.sh → mentat-only overrides (laptop used as a home server); run by dotfiles.sh when hostname is mentat
# Usage: bash ~/ledot/setup/dotfiles.mentat.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

[ "$(hostname)" = "mentat" ] || die "dotfiles.mentat.sh is for mentat only (this is $(hostname))"

# install_conf <dst> — write stdin to <dst> (root, 644) if it differs; returns 1 if already up to date
install_conf() {
    local dst="$1" tmp
    tmp="$(mktemp)"
    cat > "$tmp"
    if sudo cmp -s "$tmp" "$dst" 2>/dev/null; then
        rm -f "$tmp"
        info "${dst} up to date"
        return 1
    fi
    sudo install -D -m 644 "$tmp" "$dst"
    rm -f "$tmp"
    info "installed ${dst}"
}

# Lid closed: keep running. logind re-reads its config on SIGHUP (a restart would kill the graphical session).
setup_lid() {
    install_conf /etc/systemd/logind.conf.d/ledot-lid.conf <<'CONF' || return 0
# mentat only — installed by ~/ledot/setup/dotfiles.mentat.sh
# Lid closed: keep running (laptop used as a server)
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
CONF
    sudo systemctl kill -s HUP systemd-logind && info "systemd-logind reloaded"
}

# Never sleep. GDM's greeter and the GNOME session default to suspend after 15 min idle on AC,
# which took mentat — and the Cloudflare tunnel / Tailscale with it — offline (2026-11-11).
# With these off, logind refuses every suspend/hibernate request, whoever sends it. No reload needed.
setup_nosleep() {
    install_conf /etc/systemd/sleep.conf.d/ledot-nosleep.conf <<'CONF' || true
# mentat only — installed by ~/ledot/setup/dotfiles.mentat.sh
# Server: never sleep (GDM/GNOME idle-suspend took mentat offline, 2026-11-11)
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowHybridSleep=no
AllowSuspendThenHibernate=no
CONF
}

header "mentat overrides"
setup_lid
setup_nosleep
