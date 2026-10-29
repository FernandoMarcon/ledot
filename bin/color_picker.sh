#!/bin/bash
# color_picker.sh — pick a screen color with hyprpicker, copy hex to clipboard
# Usage: color_picker.sh

set -euo pipefail

command -v hyprpicker >/dev/null || { echo "hyprpicker not found: run setup/display.sh" >&2; exit 1; }

color="$(hyprpicker -a -b -f hex -r)"
[ -n "${color}" ] || exit 0  # cancelled with Esc

notify-send -t 2000 "Color copied" "${color}"
