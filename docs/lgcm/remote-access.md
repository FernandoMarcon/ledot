# Remote Access to lgcm (work PC)

`lgcm` (Ubuntu 26.04, HC/USP network) is reachable from my devices over **Tailscale SSH**.
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

## Check

```bash
systemctl is-active openvpn-client@proton tailscaled
ip -br addr show tun0                                   # 10.98.x.x
curl -s https://cloudflare.com/cdn-cgi/trace | grep ip= # Proton IP, not 200.144.29.76
resolvectl dns tun0                                     # 10.98.0.1
tailscale status                                        # no "Health check" block
tailscale ping bv9300-pro                               # pong ... via DERP(sao)
```

Logs: `sudo journalctl -u openvpn-client@proton -n 30 --no-pager`

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Options error: Cannot parse argument 'unlimited'` | `connect-retry-max unlimited` in the config: delete the line |
| `DEPRECATED OPTION: --persist-key` | harmless (Proton's config, OpenVPN 2.7) |
| Tailscale health check mentions Fortinet / São Paulo relay | VPN down → `systemctl status openvpn-client@proton` |
| Tailscale broken after VPN reconnects | `sudo systemctl restart tailscaled` |
| `cloudflared.service` restarting forever | leftover from the failed tunnel attempt: `sudo systemctl disable --now cloudflared` |

## Leftovers to clean
- `sudo systemctl disable --now cloudflared`, `sudo rm -rf /etc/cludflared /etc/cloudflared/token`
- Delete the `lgcm` tunnel in the Cloudflare Zero Trust dashboard, if created.
- ufw allows `3000/tcp`, `7687/tcp`, `22/tcp` from **Anywhere** on the hospital network: restrict or remove if unused.
