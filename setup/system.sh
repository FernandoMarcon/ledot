#!/bin/bash
# system.sh — pkgs/system.list: disks, power (desktop)
# Usage: bash ~/ledot/setup/system.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

install_list system
