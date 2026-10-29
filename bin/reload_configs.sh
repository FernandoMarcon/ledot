#!/bin/bash
# reload_configs.sh — reload hyprland, waybar, swaync, hyprsunset, kitty and tmux configs
# Usage: reload_configs.sh
# Alacritty needs nothing: live_config_reload = true

set -uo pipefail

CONFIG="$HOME/.config"

hyprctl reload >/dev/null

# Waybar: launcher rebuilds runtime config and restarts it
"$CONFIG/waybar/scripts/launch.sh" >/dev/null 2>&1

# Notifications: reload config and css
pgrep -x swaync >/dev/null && swaync-client -R -rs >/dev/null

# Night light: re-reads hypr/hyprsunset.conf only on start
if pgrep -x hyprsunset >/dev/null; then
    pkill -x hyprsunset
    while pgrep -x hyprsunset >/dev/null; do sleep 0.1; done
    hyprctl dispatch "hl.dsp.exec_cmd('hyprsunset')" >/dev/null
fi

# Kitty: SIGUSR1 reloads kitty.conf in every instance
pkill -USR1 -x kitty

# Tmux: re-source config if a server is running
tmux has-session 2>/dev/null && tmux source-file "$CONFIG/tmux/tmux.conf"

errors="$(hyprctl configerrors)"
if [ -n "${errors//[[:space:]]/}" ]; then
    notify-send -u critical "Hyprland config errors" "${errors}"
else
    notify-send -t 2000 "Configs reloaded"
fi
