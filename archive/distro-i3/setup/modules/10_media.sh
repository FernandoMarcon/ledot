#!/usr/bin/env bash
## Module 10 – Media tools
## MPD (music daemon), MPC (CLI client shown in Polybar), FFmpeg (screen recording).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "Media (MPD, MPC, FFmpeg)"

apt_install mpd mpc ffmpeg

# Create a minimal MPD config if none exists
MPD_CONF="$HOME/.config/mpd/mpd.conf"
if [[ ! -f "$MPD_CONF" ]]; then
    mkdir -p "$HOME/.config/mpd" "$HOME/Music" "$HOME/.local/share/mpd"
    cat > "$MPD_CONF" <<EOF
music_directory    "~/Music"
playlist_directory "~/.local/share/mpd/playlists"
db_file            "~/.local/share/mpd/database"
log_file           "~/.local/share/mpd/mpd.log"
pid_file           "~/.local/share/mpd/pid"
state_file         "~/.local/share/mpd/state"

audio_output {
    type  "pipewire"
    name  "PipeWire Output"
}
EOF
    mkdir -p "$HOME/.local/share/mpd/playlists"
    log_ok "MPD config created at $MPD_CONF"
else
    log_warn "MPD config already exists – not overwriting"
fi

log_ok "Media tools installed"
