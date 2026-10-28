#!/usr/bin/env bash
# Launches apps into workspaces on i3 start.
# Uses pgrep guards so a reload never re-launches running apps.

HOST=$(hostname)

_launch() {
  local ws="$1" cmd="$2" proc="$3"
  pgrep -x "$proc" > /dev/null && return
  i3-msg "workspace $ws; exec --no-startup-id $cmd"
  # Wait up to 15s for the process to start, then give the window time to map
  local i=0
  until pgrep -x "$proc" >/dev/null 2>&1; do
    sleep 0.5
    i=$((i + 1))
    [ $i -ge 30 ] && break
  done
  sleep 1.5
}

# Give display_setup.sh time to configure xrandr first
sleep 3

case "$HOST" in
  carbon)
    # ws1: brave   ws2: terminal   ws3: obsidian
    #_launch 1 brave-browser brave
    #_launch 2 alacritty     alacritty
    #_launch 3 obsidian      obsidian
    ;;
  lgcm)
    # ws1 (VGA): terminal   ws2 (HDMI): brave   ws3 (HDMI): obsidian
    _launch 1 alacritty     alacritty
    #_launch 2 brave-browser brave
    #_launch 3 obsidian      obsidian
    ;;
  *)
    # fallback
    _launch 1 alacritty alacritty
    ;;
esac

~/ledot/tmux/load_sessions.sh
~/ledot/second-brain/setup.sh
