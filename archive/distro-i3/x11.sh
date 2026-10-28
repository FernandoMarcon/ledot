#!/bin/bash
# x11.sh — x11.list (archived): legacy i3/X11 session (configs in archive/). Not installed by default.
# Usage: bash ~/.dotfiles/archive/distro-i3/x11.sh

set -euo pipefail
source "${HOME}/.dotfiles/setup/lib/common.sh"

grep -vE "^\s*(#|$)" "$(dirname "${BASH_SOURCE[0]}")/x11.list" | xargs sudo apt-get install -y
