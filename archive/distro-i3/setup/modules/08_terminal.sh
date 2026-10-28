#!/usr/bin/env bash
## Module 08 – Terminal emulators
## Alacritty (default in keybindings) and Kitty (Alt+Ctrl+T).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "Terminals (Alacritty + Kitty)"

apt_install alacritty kitty

log_ok "Terminals installed"
