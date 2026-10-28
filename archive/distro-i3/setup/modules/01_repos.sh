#!/usr/bin/env bash
## Module 01 – APT repositories
## Enables universe, updates package lists.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "APT Repositories"

# Enable universe (most packages live here)
if ! apt-cache policy 2>/dev/null | grep -q "ubuntu.*/universe"; then
    log_info "Enabling universe repository..."
    sudo add-apt-repository -y universe
    log_ok "universe enabled"
else
    log_ok "universe already enabled"
fi

# Update & upgrade
log_info "Updating package lists..."
sudo apt-get update -qq

log_info "Upgrading installed packages..."
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

log_ok "Repositories up to date"
