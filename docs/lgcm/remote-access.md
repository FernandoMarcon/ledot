# Remote Access to lgcm (work PC)

`lgcm` (Ubuntu 26.04, HC/USP network) is reachable from my devices over **Tailscale SSH**
and over a **Cloudflare Tunnel** (`lgcm.marconp.com`, behind Cloudflare Access).
The work network's Fortinet firewall blocks the usual paths, so all traffic leaves through
**Proton VPN (OpenVPN TCP)**, running as a system service. IT approved this workaround (2026-11-05).

```
phone/laptop ──tailnet──> DERP relay (sao) <── Tailscale <── Proton OpenVPN TCP/443 <── lgcm
```

- Tailscale IP: `100.83.194.125` (MagicDNS name: `lgcm`)
- Connect: `ssh fernando@lgcm`. Tailscale SSH: no keys, auth by tailnet identity (may ask for browser approval).

## Why this setup

What the work network blocks (tested 2026-11-05):

| Path | Result |
|---|---|
| Cloudflare Tunnel (`cloudflared`, edge port 7844) | blocked (no fallback to 443, service times out) |
| Tailscale DERP relays | blocked (`tailscale status`: *"Network equipment from Fortinet may be blocking"*) |
| Tailscale direct UDP | works on this side, but phones on mobile data (CGNAT) need a relay |
| Proton VPN WireGuard | connection timed out |
| Proton VPN OpenVPN (TCP) | **works** |

The local firewall (ufw) is not the problem: outgoing traffic is allowed.
Proton's Linux app has no Stealth protocol, so OpenVPN TCP is the only option that gets through.

## Setup

### 1. Proton files
On account.protonvpn.com:
- **Downloads → OpenVPN configuration files**: Linux, **TCP**, **Country configs → Brazil** → `br.protonvpn.tcp.ovpn`.
  Use a country config: it lists several servers, so OpenVPN fails over if one is down.
- **Account → OpenVPN / IKEv2 username**: OpenVPN credentials (different from the Proton login).

### 2. Install the service
```bash
sudo bash ~/ledot/docs/lgcm/setup-proton-service.sh ~/Downloads/br.protonvpn.tcp.ovpn
```
The script ([setup-proton-service.sh](setup-proton-service.sh)) is safe to re-run. It:
- installs `openvpn-systemd-resolved` (VPN DNS via systemd-resolved; Proton's configs assume `resolvconf`)
- copies the config to `/etc/openvpn/client/proton.conf` and appends `auth-user-pass`, `update-systemd-resolved` hooks
  and `connect-retry 5 30` (retries are unlimited by default; `connect-retry-max unlimited` is **invalid** and makes OpenVPN exit)
- prompts once for the credentials → `/etc/openvpn/client/proton.auth` (root, `600`)
- drop-in `openvpn-client@proton.service.d/override.conf`: `Restart=always`, no start limit
- drop-in `tailscaled.service.d/after-proton.conf`: starts after the VPN, `Restart=always`
- enables `openvpn-client@proton` (starts at boot, no login needed)

### 3. Tailscale SSH
```bash
sudo tailscale set --ssh
```

### 4. Don't sleep
```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

### 5. Proton desktop app
Must **not** connect on lgcm: two tunnels conflict. Its Hyprland autostart
(`config/hypr/modules/autostart.lua`) skips hostname `lgcm`; keep its *Auto connect* setting `Off`.

### 6. Cloudflare Tunnel (second path, works through the VPN)
Fallback for devices without Tailscale. Port 7844 is reachable once traffic goes through Proton.

1. Zero Trust → Networks → Tunnels → **Create tunnel** `lgcm` → copy only the token (`eyJ...`).
2. **Access app first**: Access → Applications → Self-hosted, domain `lgcm.marconp.com`,
   policy `ssh-mentat` (my email), **Browser rendering off** (on = `websocket: bad handshake`).
3. Token + service (native `cloudflared`, `ExecStart=... tunnel run --token-file /etc/cloudflared/token`):
   ```bash
   sudo sh -c 'read -r t; printf %s "$t" > /etc/cloudflared/token' && sudo chmod 600 /etc/cloudflared/token
   sudo install -d /etc/systemd/system/cloudflared.service.d
   sudo tee /etc/systemd/system/cloudflared.service.d/after-proton.conf <<'EOF'
   [Unit]
   Wants=openvpn-client@proton.service
   After=openvpn-client@proton.service
   StartLimitIntervalSec=0

   [Service]
   TimeoutStartSec=60
   Restart=always
   RestartSec=10
   EOF
   sudo systemctl daemon-reload && sudo systemctl enable --now cloudflared
   ```
4. Tunnel → Public Hostname → Add: `lgcm` / `marconp.com` / **`ssh://localhost:22`**.
5. sshd is key-only (`/etc/ssh/sshd_config.d/10-hardening.conf`: no password, no root).

Client (`~/.ssh/config`, device's pubkey must be in lgcm's `~/.ssh/authorized_keys`):
```
Host lgcm-cf
	Hostname lgcm.marconp.com
	User fernando
	IdentityFile ~/.ssh/id_ed25519
	IdentitiesOnly yes
	ProxyCommand cloudflared access ssh --hostname %h
```
First use: `cloudflared access login lgcm.marconp.com` (browser, email code).
Host key: `ssh-ed25519 SHA256:aBFoMMnHbwJldtB43tSKI2M7dSuo5aeV7D/UkJIL1MU`.

## Check

```bash
systemctl is-active openvpn-client@proton tailscaled
ip -br addr show tun0                                   # 10.98.x.x
curl -s https://cloudflare.com/cdn-cgi/trace | grep ip= # Proton IP, not 200.144.29.76
resolvectl dns tun0                                     # 10.98.0.1
tailscale status                                        # no "Health check" block
tailscale ping bv9300-pro                               # pong ... via DERP(sao)
systemctl is-active cloudflared                         # tunnel Healthy in dashboard
dig +short @1.1.1.1 lgcm.marconp.com                    # must resolve (NXDOMAIN = route/DNS missing)
curl -sI https://lgcm.marconp.com | head -1             # 302 → Access login
```

Logs: `sudo journalctl -u openvpn-client@proton -n 30 --no-pager`

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Options error: Cannot parse argument 'unlimited'` | `connect-retry-max unlimited` in the config: delete the line |
| `DEPRECATED OPTION: --persist-key` | harmless (Proton's config, OpenVPN 2.7) |
| Tailscale health check mentions Fortinet / São Paulo relay | VPN down → `systemctl status openvpn-client@proton` |
| Tailscale broken after VPN reconnects | `sudo systemctl restart tailscaled` |
| `cloudflared` start timeout, port 7844 blocked | VPN down (cloudflared only works through Proton here) |
| `websocket: bad handshake` | Access app has Browser rendering on → turn it off |
| `530` / `error code: 1033` | DNS record points to another tunnel → delete record, re-add the public hostname |
| `ssh HPC` / GitLab / INCOR hosts time out | VPN routes the hospital LAN (`172.16.0.0/12`) into the tunnel → config needs `route 172.16.0.0 255.240.0.0 net_gateway` (added by the script); check `ip route get 172.22.132.113` is **not** `dev tun0` |
| `no such host` / NXDOMAIN | DNS record missing → delete and re-add the route; `sudo resolvectl flush-caches` |

## Notes
- ufw allows `3000/tcp`, `7687/tcp`, `22/tcp` from **Anywhere** on the hospital network: restrict or remove if unused.
