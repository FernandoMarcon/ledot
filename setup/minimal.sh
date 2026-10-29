#!/bin/bash
# minimal.sh → pkgs/minimal.list: essentials for a working CLI system
# Also: GitHub CLI repo (newer gh), timezone
# Usage: bash ~/ledot/setup/minimal.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

TZ_NAME="America/Sao_Paulo"

# ── Timezone ─────────────────────────────────────────────────────────────────
current=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null)
if [ "$current" = "$TZ_NAME" ]; then
    info "Timezone already set to $TZ_NAME"
else
    info "Setting timezone to $TZ_NAME..."
    sudo timedatectl set-timezone "$TZ_NAME"
    sudo timedatectl set-ntp true
    info "Timezone: $(timedatectl show --property=Timezone --value)"
fi

# ── GitHub CLI repo ──────────────────────────────────────────────────────────
if ! grep -rq "cli.github.com" /etc/apt/sources.list.d/ 2>/dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg status=none
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    info "GitHub CLI repo added"
fi

sudo apt-get update -qq
install_list minimal
