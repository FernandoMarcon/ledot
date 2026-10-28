#!/usr/bin/env bash
# Configures displays via xrandr and restarts polybar.
# Called by i3 exec_always so it runs on every reload.

HOST=$(hostname)

case "$HOST" in
  carbon)
    if xrandr | grep -q "^HDMI-1 connected"; then
      xrandr --output HDMI-1 --auto --primary \
             --output eDP-1 --off
    else
      xrandr --output eDP-1 --auto --primary \
             --output HDMI-1 --off
    fi
    ;;
  lgcm)
    VGA=$(xrandr  | awk '/^DP-0[^ ]* connected/ {print $1; exit}')
    HDMI=$(xrandr | awk '/^HDMI[^ ]* connected/ {print $1; exit}')
    if [[ -n "$VGA" && -n "$HDMI" ]]; then
      xrandr --output "$HDMI" --auto --primary \
             --output "$VGA"  --auto --left-of "$HDMI"
    fi
    ;;
esac

# Restart polybar so it lands on the correct monitor(s)
sleep 0.5
"$HOME"/.dotfiles/polybar/launch.sh
