#!/bin/bash
# minimal.sh → pkgs/minimal.list: essentials for a working CLI system
# Also: GitHub CLI repo (newer gh), timezone, en_US.UTF-8 locale, sshd enabled
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

# ── Locale ───────────────────────────────────────────────────────────────────
# Fresh Ubuntu ships only C.UTF-8; apps that set en_US (e.g. ElegooSlicer) fail without it. LANG is left as is.
command -v locale-gen &>/dev/null || sudo apt-get install -y locales
if locale -a | grep -qi '^en_US\.utf-\?8$'; then
    info "Locale en_US.UTF-8 already generated"
else
    sudo locale-gen en_US.UTF-8
    info "Locale en_US.UTF-8 generated"
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

apt_update
install_list minimal

# ── SSH server ───────────────────────────────────────────────────────────────
# Ubuntu ≥24.04 socket-activates sshd (ssh.service stays inactive until a connection);
# switch to the always-on service, per Ubuntu's documented recipe
if systemctl is-enabled ssh.service &>/dev/null && systemctl is-active ssh.service &>/dev/null; then
    info "SSH server already enabled and active"
else
    if systemctl list-unit-files ssh.socket &>/dev/null; then
        sudo systemctl disable --now ssh.socket 2>/dev/null || true
        sudo rm -f /etc/systemd/system/ssh.service.d/00-socket.conf /etc/systemd/system/ssh.socket.d/addresses.conf
        sudo systemctl daemon-reload
    fi
    sudo systemctl enable --now ssh.service
    info "SSH server: $(systemctl is-active ssh.service), $(systemctl is-enabled ssh.service)"
fi
