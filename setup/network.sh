#!/bin/bash
# network.sh — pkgs/network.list: VPN, remote filesystems, mesh networking
# Also: Tailscale repo, vpn-slice
# Usage: bash ~/ledot/setup/network.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ── Tailscale repo ───────────────────────────────────────────────────────────
if ! grep -rq "pkgs.tailscale.com" /etc/apt/sources.list.d/ 2>/dev/null; then
    curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/$(lsb_release -cs).noarmor.gpg" \
        | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu $(lsb_release -cs) main" \
        | sudo tee /etc/apt/sources.list.d/tailscale.list > /dev/null
    sudo apt-get update -qq
    info "Tailscale repo added"
fi

install_list network

# ── vpn-slice ────────────────────────────────────────────────────────────────
# Used by ~/tools/vpn to route only internal IPs (INCOR, GitLab) through the tunnel
pipx_install vpn-slice
