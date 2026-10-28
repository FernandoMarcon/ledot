#!/bin/bash
# display.sh — pkgs/display.list: brightness, screenshots
# Usage: bash ~/ledot/setup/display.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

install_list display
