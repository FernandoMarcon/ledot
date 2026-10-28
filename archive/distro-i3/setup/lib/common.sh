#!/usr/bin/env bash
## Shared utilities for all setup modules

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log_section() { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════${RESET}"; echo -e "${BOLD}${CYAN}  $*${RESET}"; echo -e "${BOLD}${CYAN}══════════════════════════════════════${RESET}"; }
log_ok()      { echo -e "${GREEN}  ✔ $*${RESET}"; }
log_warn()    { echo -e "${YELLOW}  ⚠ $*${RESET}"; }
log_error()   { echo -e "${RED}  ✖ $*${RESET}" >&2; }
log_info()    { echo -e "  → $*"; }

# apt install wrapper - silent on already-installed, exits on real failure
apt_install() {
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

# Check if a command exists
has_cmd() { command -v "$1" &>/dev/null; }

# Check if an apt package is installed
pkg_installed() { dpkg -s "$1" &>/dev/null; }

# Run only if binary is not already present
install_if_missing() {
    local binary="$1"; shift
    if has_cmd "$binary"; then
        log_ok "$binary already installed, skipping"
    else
        "$@"
    fi
}
