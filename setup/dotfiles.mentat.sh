#!/bin/bash
# dotfiles.mentat.sh → mentat-only overrides (home server); run by dotfiles.sh when hostname is mentat
# Usage: bash ~/ledot/setup/dotfiles.mentat.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

[ "$(hostname)" = "mentat" ] || die "dotfiles.mentat.sh is for mentat only (this is $(hostname))"

# Never sleep. GDM's greeter and the GNOME session default to suspend after 15 min idle on AC,
# which took mentat — and the Cloudflare tunnel / Tailscale with it — offline (2026-11-11).
# With these off, logind refuses every suspend/hibernate request, whoever sends it. No reload needed.
setup_nosleep() {
    local dst=/etc/systemd/sleep.conf.d/ledot-nosleep.conf tmp
    tmp="$(mktemp)"
    cat > "$tmp" <<'CONF'
# mentat only — installed by ~/ledot/setup/dotfiles.mentat.sh
# Server: never sleep (GDM/GNOME idle-suspend took mentat offline, 2026-11-11)
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowHybridSleep=no
AllowSuspendThenHibernate=no
CONF
    if sudo cmp -s "$tmp" "$dst" 2>/dev/null; then
        info "nosleep: ${dst} up to date"
    else
        sudo install -D -m 644 "$tmp" "$dst"
        info "nosleep: installed ${dst}"
    fi
    rm -f "$tmp"
}

header "mentat overrides"
setup_nosleep
