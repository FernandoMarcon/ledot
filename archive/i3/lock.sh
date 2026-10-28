#!/bin/bash
# Keep screen on for 30 min while locked; restore DPMS to system default after unlock
xset dpms 1800 1800 1800
TMP=$(mktemp --suffix=.png)
RES=$(xdpyinfo | awk '/dimensions/{print $2}')
convert -size "$RES" xc:black \
  -font "DejaVu-Sans-Bold" \
  -pointsize 100 \
  -fill white \
  -gravity center \
  -annotate 0 "Volto                 logo!" \
  "$TMP"
i3lock -i "$TMP"
rm -f "$TMP"
# Restore: 0 0 0 = use system/X defaults (DPMS disabled unless set elsewhere)
xset dpms 0 0 0
