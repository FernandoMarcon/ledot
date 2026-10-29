#!/bin/bash
# audio.sh → pkgs/audio.list: PipeWire stack, mixers, visualizer
# Usage: bash ~/ledot/setup/audio.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

install_list audio
