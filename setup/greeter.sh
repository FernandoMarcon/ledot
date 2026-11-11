#!/bin/bash
# greeter.sh — greetd + tuigreet login on tty1, with boot/kernel console output kept off it
# Usage: bash ~/ledot/setup/greeter.sh  (reboot to apply)

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

if is_work; then
    info "Work PC (lgcm) — keeping current display manager, skipping greeter"
    exit 0
fi

# Replaces the current display manager (e.g. gdm3), so it asks first; default no
dm="$(basename "$(readlink /etc/systemd/system/display-manager.service 2>/dev/null || echo none)" .service)"
if [ "$dm" = "greetd" ]; then
    info "greetd is already the display manager"
elif ! confirm_no "Replace display manager (${dm}) with greetd + tuigreet?"; then
    info "Skipping greeter"
    exit 0
fi

sudo apt-get install -y greetd tuigreet

# ── greetd: tuigreet on tty1 ─────────────────────────────────────────────────
sudo tee /etc/greetd/config.toml > /dev/null <<'CONF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --asterisks --cmd start-hyprland"
user = "_greetd"
CONF

# Start after boot jobs finish and take a fresh, cleared VT, so systemd status
# lines don't print over the greeter; greeter stderr goes to the journal.
# Ubuntu's greetd unit only conflicts with getty@tty7, but Ubuntu Server enables
# getty@tty1: agetty then shares tty1 with greetd and takes the VT back when the
# session starts, killing Hyprland and leaving a plain "login:" prompt
sudo mkdir -p /etc/systemd/system/greetd.service.d
sudo tee /etc/systemd/system/greetd.service.d/override.conf > /dev/null <<'CONF'
[Unit]
Conflicts=getty@tty1.service
After=getty@tty1.service

[Service]
Type=idle
StandardInput=tty
StandardOutput=tty
StandardError=journal
TTYReset=true
TTYVHangup=true
TTYVTDisallocate=true
CONF
sudo systemctl daemon-reload
sudo systemctl disable getty@tty1.service 2>/dev/null || true
# --force replaces the display-manager.service alias another DM (gdm3) holds
sudo systemctl enable --force greetd
info "greetd configured"

# ── Kernel console: errors and below stay in the journal ─────────────────────
# Ubuntu's 10-console-messages.conf sets console level 4 (shows KERN_ERR, e.g.
# mmc0 SD-reader errors); 3 shows only crit/alert/emerg
echo 'kernel.printk = 3 3 3 3' | sudo tee /etc/sysctl.d/20-quiet-printk.conf > /dev/null
sudo sysctl -q -p /etc/sysctl.d/20-quiet-printk.conf

# Same from early boot, plus no systemd [ OK ] status lines
sudo tee /etc/default/grub.d/quiet-console.cfg > /dev/null <<'CONF'
GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3"
CONF
sudo update-grub
info "Quiet console configured — reboot to apply"
