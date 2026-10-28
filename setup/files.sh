#!/bin/bash
# files.sh — pkgs/files.list: ranger previews, archives, file utilities
# Usage: bash ~/.dotfiles/setup/files.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

install_list files
