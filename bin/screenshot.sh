#!/bin/bash
# screenshot.sh — select a region, copy it to the clipboard and save it to ~/Images/Screenshots
# Usage: screenshot.sh

set -euo pipefail

[ -d "${HOME}/Images" ] && dir="${HOME}/Images"
[ -d "${HOME}/Imagens" ] && dir="${HOME}/Imagens"
# dir="${HOME}/Images/Screenshots"
mkdir -p "${dir}"

geometry="$(slurp)" || exit 0  # cancelled with Esc
file="${dir}/Screenshot_$(date '+%d-%b_%H-%M-%S')_${RANDOM}.png"

grim -g "${geometry}" "${file}"
wl-copy --type image/png < "${file}"
notify-send -t 2000 -i "${file}" "Screenshot saved" "${file/#${HOME}/\~}"
