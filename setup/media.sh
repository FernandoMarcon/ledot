#!/bin/bash
# media.sh → pkgs/media.list + media.flatpak: players, downloaders, image tools, Grayjay, FCast, Stremio
# Usage: bash ~/ledot/setup/media.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

install_list media
install_flatpaks media
