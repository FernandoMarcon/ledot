#!/usr/bin/env bash
## Module 07 – Audio stack
## Ubuntu 24.04 server ships without audio. We install PipeWire + PulseAudio
## compatibility layer, then pulsemixer (the CLI mixer used by i3_volume).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "Audio (PipeWire + pulsemixer)"

apt_install \
    pipewire \
    pipewire-pulse \
    pipewire-audio \
    wireplumber \
    pulsemixer \
    pavucontrol \
    alsa-utils

# Enable PipeWire for the current user (systemd user session)
if has_cmd systemctl; then
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || \
        log_warn "Could not enable PipeWire user services (no user session yet — will start on login)"
fi

log_ok "Audio stack installed"
