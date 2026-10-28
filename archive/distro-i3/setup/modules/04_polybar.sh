#!/usr/bin/env bash
## Module 04 – Polybar status bar
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "Polybar"

# upower is used by polybar.sh for battery/adapter detection
apt_install polybar upower acpi

log_ok "Polybar installed"
