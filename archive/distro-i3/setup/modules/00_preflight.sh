#!/usr/bin/env bash
## Module 00 – Preflight checks
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "Preflight Checks"

# Must not be root (we use sudo where needed)
if [[ "$EUID" -eq 0 ]]; then
    log_error "Run as a regular user, not root. The script will call sudo as needed."
    exit 1
fi
log_ok "Running as regular user: $(whoami)"

# Ubuntu 24.04
. /etc/os-release
if [[ "$ID" != "ubuntu" || "$VERSION_ID" != "24.04" ]]; then
    log_warn "Detected: $PRETTY_NAME — these scripts target Ubuntu 24.04. Proceed at your own risk."
else
    log_ok "Ubuntu 24.04 detected"
fi

# sudo access
if ! sudo -n true 2>/dev/null; then
    log_info "Sudo requires a password. You may be prompted multiple times."
    sudo true || { log_error "sudo access required"; exit 1; }
fi
log_ok "sudo access confirmed"

# Internet
if ! curl -sf --connect-timeout 5 https://deb.debian.org > /dev/null; then
    log_error "No internet connection detected. Aborting."
    exit 1
fi
log_ok "Internet connectivity OK"

# Disk space (require at least 4 GB free)
AVAIL_KB=$(df --output=avail / | tail -1)
if (( AVAIL_KB < 4194304 )); then
    log_warn "Less than 4 GB free on /. Installation may fail."
else
    log_ok "Disk space OK ($(( AVAIL_KB / 1024 / 1024 )) GB free)"
fi
