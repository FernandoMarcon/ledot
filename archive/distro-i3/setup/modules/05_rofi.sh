#!/usr/bin/env bash
## Module 05 – Rofi launcher & applets
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "Rofi"

apt_install rofi

log_ok "Rofi installed"
