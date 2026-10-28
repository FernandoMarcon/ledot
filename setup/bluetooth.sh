#!/bin/bash
# bluetooth.sh — pkgs/bluetooth.list: bluetooth
# Usage: bash ~/.dotfiles/setup/bluetooth.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

install_list bluetooth
