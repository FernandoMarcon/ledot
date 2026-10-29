#!/bin/bash
# carbon.sh → pkgs/carbon.list: ThinkPad X1 Carbon 5th gen quirks (thermals, uncore perf, SD card reader, WWAN modem)
# Usage: bash ~/ledot/setup/carbon.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

MODEL="$(cat /sys/class/dmi/id/product_version 2>/dev/null || true)"
if [[ "$MODEL" != *"X1 Carbon"* ]]; then
    warn "This machine is '${MODEL:-unknown}', not a ThinkPad X1 Carbon"
    confirm_no "Apply Carbon tweaks anyway?" || exit 0
fi

install_list carbon

# ── 1. Thermals: load coretemp + RAPL at early boot, before thermald starts ──
# Otherwise thermald logs "NO RAPL sysfs present" / "No coretemp sysfs found" and runs without zones
MODULES_CONF="/etc/modules-load.d/carbon.conf"
printf 'coretemp\nintel_rapl_msr\n' | sudo tee "$MODULES_CONF" >/dev/null
info "Early-load modules: $MODULES_CONF (coretemp, intel_rapl_msr)"

# ── 2. Uncore perf counters: their IMC init maps past the firmware's PNP0C02 reservation ──
# ("resource sanity check: requesting [mem 0xfed10000-0xfed15fff] ... snb_uncore_imc_init_box").
# intel_uncore is built in, so skip its initcall; only perf's uncore_* PMUs are lost
GRUB_CFG="/etc/default/grub.d/carbon.cfg"
# shellcheck disable=SC2016  # expanded by grub, not here
GRUB_LINE='GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT initcall_blacklist=intel_uncore_init"'
if [ "$(cat "$GRUB_CFG" 2>/dev/null)" = "$GRUB_LINE" ]; then
    info "intel_uncore already skipped at boot ($GRUB_CFG)"
else
    echo "$GRUB_LINE" | sudo tee "$GRUB_CFG" >/dev/null
    sudo update-grub
    info "intel_uncore skipped at boot ($GRUB_CFG) — reboot to apply"
fi

# ── 3. SD card reader (Realtek RTS525A) ──────────────────────────────────────
# Fails with "mmc0: Card stuck being busy" / "error -110" at every boot; blacklisting the driver silences it
SDCARD_CONF="/etc/modprobe.d/carbon-sdcard.conf"
if [ -f "$SDCARD_CONF" ]; then
    info "SD card reader already disabled ($SDCARD_CONF)"
elif confirm "Disable the SD card reader (rtsx_pci_sdmmc)?"; then
    echo "blacklist rtsx_pci_sdmmc" | sudo tee "$SDCARD_CONF" >/dev/null
    sudo update-initramfs -u
    info "SD card reader disabled (re-enable: sudo rm $SDCARD_CONF && sudo update-initramfs -u)"
fi

# ── 4. WWAN modem (Sierra EM7455) without a SIM ──────────────────────────────
# ModemManager retries it every boot ("SIM not inserted") and NetworkManager warns on cdc-wdm0
if ! systemctl is-enabled ModemManager &>/dev/null; then
    info "ModemManager already disabled"
elif confirm "Disable ModemManager (no SIM in the WWAN modem)?"; then
    sudo systemctl disable --now ModemManager
    info "ModemManager disabled (re-enable: sudo systemctl enable --now ModemManager)"
fi
