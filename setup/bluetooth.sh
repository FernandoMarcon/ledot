#!/bin/bash
# bluetooth.sh → pkgs/bluetooth.list: bluetooth
# Usage: bash ~/ledot/setup/bluetooth.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

if ! "${DOTFILES}/bin/get_bluetooth.sh"; then
    info "No bluetooth adapter — skipping"
    exit 0
fi

install_list bluetooth

# bluetooth.service declares ConfigurationDirectoryMode=0555 and warns on every start if /etc/bluetooth differs
sudo chmod 555 /etc/bluetooth
info "/etc/bluetooth mode set to 555"
