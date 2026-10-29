#!/bin/bash
# tools.sh → pkgs/tools.list: everyday handy tools
# Usage: bash ~/ledot/setup/tools.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

install_list tools
