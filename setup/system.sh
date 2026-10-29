#!/bin/bash
# system.sh → pkgs/system.list: disks, power, monitoring (desktop)
# Usage: bash ~/ledot/setup/system.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

install_list system

# UPower is only D-Bus activated by default; start it at boot so WirePlumber etc. can read the battery
sudo systemctl enable --now upower
info "upower enabled"
