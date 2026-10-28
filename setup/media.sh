#!/bin/bash
# media.sh — pkgs/media.list: players, downloaders, image tools
# Usage: bash ~/.dotfiles/setup/media.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

install_list media
