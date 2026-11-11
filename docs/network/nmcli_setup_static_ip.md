# Static IP with NetworkManager (nmcli)

For a fresh Ubuntu Server install where `network-manager` was installed afterwards. Example values: LAN `192.168.15.0/24`, gateway `192.168.15.1`, host IP `192.168.15.201`.

**Why this is needed:** a static IP set in the Ubuntu installer goes into netplan with the `systemd-networkd` renderer. NetworkManager then leaves the cable *unmanaged*, and a Wi-Fi connection created with `nmcli` uses DHCP (that's where a stray address like `.18` comes from). The fix is to hand everything to NetworkManager.

Run this from the machine's own screen and keyboard, not over SSH. The network drops partway through.

## 1. Check the current state
```bash
ip -br a; ip route          # which interface has which IP, and the gateway
nmcli dev status            # ethernet "unmanaged" = netplan/networkd owns it
cat /etc/netplan/*.yaml
```

## 2. Hand the network to NetworkManager
```bash
sudo mkdir -p ~/netplan.bak && sudo mv /etc/netplan/*.yaml ~/netplan.bak/
printf 'network:\n  version: 2\n  renderer: NetworkManager\n' | sudo tee /etc/netplan/01-nm.yaml
sudo chmod 600 /etc/netplan/01-nm.yaml
# only if cloud-init is installed, so it doesn't rewrite netplan on the next boot:
[ -d /etc/cloud ] && echo 'network: {config: disabled}' | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
sudo netplan apply
sudo systemctl disable --now systemd-networkd systemd-networkd-wait-online
```

## 3. Cable with a fixed IP
Get the real interface name from `ip -br link` (starts with `en`). Using the wrong name gives `No suitable device found for this connection (... mismatching interface name)`.
```bash
sudo nmcli con delete "Wired connection 1" 2>/dev/null   # remove the automatic DHCP profile, if there is one
sudo nmcli con add type ethernet ifname <eth-name> con-name lan \
  ipv4.method manual ipv4.addresses 192.168.15.201/24 \
  ipv4.gateway 192.168.15.1 ipv4.dns "192.168.15.1,1.1.1.1" \
  ipv4.route-metric 100 connection.autoconnect yes
sudo nmcli con up lan
```
- STATE `unmanaged`: `sudo nmcli dev set <eth-name> managed yes`
- STATE `unavailable`: no cable link (`cat /sys/class/net/<eth-name>/carrier` should be `1`)
- Wrong name in the profile: `sudo nmcli con mod lan connection.interface-name <eth-name>`

## 4. Wi-Fi with a fixed IP
```bash
nmcli con show                                    # get the Wi-Fi connection's name
sudo nmcli con mod "<wifi-name>" ipv4.method manual \
  ipv4.addresses 192.168.15.201/24 ipv4.gateway 192.168.15.1 \
  ipv4.dns "192.168.15.1,1.1.1.1" ipv4.route-metric 600
sudo nmcli con up "<wifi-name>"
```
If the Wi-Fi still has an extra DHCP address, check for a second Wi-Fi profile (`nmcli -f NAME,DEVICE,TYPE con show`), check that `nmcli -g ipv4.method con show "<wifi-name>"` prints `manual`, and check that `systemd-networkd` is stopped (`networkctl`).

## 5. Same IP on cable and Wi-Fi (failover)
**Both interfaces can't hold `.201` at the same time.** The router would see one IP behind two MAC addresses, and connections would hang or drop. [`bin/70-wifi-failover`](../../bin/70-wifi-failover) is a NetworkManager dispatcher script that keeps `.201` on one interface at a time:
- cable connected → Wi-Fi down
- cable unplugged → Wi-Fi up (with the same `.201`)

Set `ETH`, `WIFI_IF` and `WIFI_CON` at the top of the script, then install it:
```bash
sudo install -o root -g root -m 755 bin/70-wifi-failover /etc/NetworkManager/dispatcher.d/
```
To test, unplug the cable. Within a few seconds `ip -br a` should show `.201` on the Wi-Fi. Plug it back in, and `.201` should return to the cable while the Wi-Fi goes down. Expect a short drop during each switch.

**Alternative:** use a different IP for the Wi-Fi (e.g. `.202`) and skip the script. Tailscale's IP and name stay the same whichever interface is up (see the homelab repo's `docs/setup_tailscale.md`).

## 6. Verify
```bash
ip -br a; ip route; nmcli dev status
```
Reboot once to confirm the settings stick. Keep the static IPs outside the router's DHCP range, or reserve them in the router.
