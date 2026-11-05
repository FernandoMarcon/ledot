#!/usr/bin/env bash
# Proton VPN (OpenVPN TCP) as a system service + Tailscale ordered after it.
# Usage: sudo bash ~/ledot/docs/lgcm/setup-proton-service.sh /path/to/br.protonvpn.tcp.ovpn
set -euo pipefail

OVPN="${1:?usage: sudo bash $0 /path/to/proton-tcp.ovpn}"
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
grep -qiE '^proto[[:space:]]+tcp' "$OVPN" || { echo "not a TCP config: $OVPN"; exit 1; }

DIR=/etc/openvpn/client
CONF=$DIR/proton.conf
AUTH=$DIR/proton.auth

# 1. DNS integration with systemd-resolved (Proton configs assume resolvconf)
apt-get install -y openvpn-systemd-resolved

# 2. Config
install -d -m 755 "$DIR"
install -m 600 "$OVPN" "$CONF"
# drop Proton's resolvconf hooks and any existing auth/script lines; re-add ours
sed -i -E '/^(up|down|down-pre|script-security|auth-user-pass)([[:space:]]|$)/d' "$CONF"
cat >> "$CONF" <<EOF

# --- added by setup-proton-service.sh ---
auth-user-pass $AUTH
auth-nocache
script-security 2
up /etc/openvpn/update-systemd-resolved
up-restart
down /etc/openvpn/update-systemd-resolved
down-pre
dhcp-option DOMAIN-ROUTE .
connect-retry 5 30
EOF

# 3. Credentials = OpenVPN/IKEv2 username + password (NOT your Proton login)
if [[ ! -s $AUTH ]]; then
  read -rp  "Proton OpenVPN username: " U
  read -rsp "Proton OpenVPN password: " P; echo
  umask 077; printf '%s\n%s\n' "$U" "$P" > "$AUTH"
fi
chmod 600 "$AUTH"

# 4. Always restart OpenVPN, forever
install -d /etc/systemd/system/openvpn-client@proton.service.d
cat > /etc/systemd/system/openvpn-client@proton.service.d/override.conf <<'EOF'
[Unit]
StartLimitIntervalSec=0

[Service]
Restart=always
RestartSec=10
EOF

# 5. Tailscale: start after the VPN, always restart
install -d /etc/systemd/system/tailscaled.service.d
cat > /etc/systemd/system/tailscaled.service.d/after-proton.conf <<'EOF'
[Unit]
Wants=openvpn-client@proton.service
After=openvpn-client@proton.service
StartLimitIntervalSec=0

[Service]
Restart=always
RestartSec=10
EOF

systemctl daemon-reload
systemctl enable --now openvpn-client@proton.service
systemctl enable tailscaled
sleep 10
systemctl restart tailscaled

echo; systemctl --no-pager -n 5 status openvpn-client@proton.service | head -5
echo; tailscale status | head -3
