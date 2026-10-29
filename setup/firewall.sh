#!/bin/bash
# firewall.sh → ufw: deny all incoming except a short allowlist; silent IGMP drop
# Usage: bash ~/ledot/setup/firewall.sh
# Resets ufw every run, so the allowlist below is the whole inbound policy.
# Docker-published ports bypass ufw; the syncthing container uses host networking instead.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

command -v ufw &>/dev/null || sudo apt-get install -y ufw

info "Resetting ufw (previous rules are backed up to /etc/ufw/*.rules.<date>)..."
sudo ufw --force reset >/dev/null

sudo ufw default deny incoming >/dev/null
sudo ufw default allow outgoing >/dev/null
sudo ufw default deny routed >/dev/null

# ── Allowlist ────────────────────────────────────────────────────────────────
sudo ufw allow in on tailscale0 to any port 22 proto tcp comment 'ssh (tailnet only)' >/dev/null
sudo ufw allow 41641/udp comment 'tailscale direct' >/dev/null
sudo ufw allow 5353/udp comment 'mdns' >/dev/null
sudo ufw allow 22000/tcp comment 'syncthing' >/dev/null
sudo ufw allow 22000/udp comment 'syncthing' >/dev/null
sudo ufw allow 21027/udp comment 'syncthing discovery' >/dev/null

# ── Drop IGMP (multicast group chatter from the router/LAN) without logging ──
# Must sit before the ufw-not-local / logging rules in before.rules
BEFORE_RULES="/etc/ufw/before.rules"
if ! sudo grep -q -- '-p igmp -j DROP' "$BEFORE_RULES"; then
    sudo sed -i '/^# ok icmp codes for INPUT/i # drop IGMP silently (ledot)\n-A ufw-before-input -p igmp -j DROP\n' "$BEFORE_RULES"
fi

sudo ufw logging low >/dev/null
sudo ufw --force enable >/dev/null
sudo systemctl enable ufw >/dev/null 2>&1
info "ufw enabled"
sudo ufw status verbose
