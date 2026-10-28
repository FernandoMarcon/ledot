#!/usr/bin/env bash
## Module 13 – Lock screen
## Installs i3lock and betterlockscreen (fancy lock with blur/dim effects).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "Lock Screen (betterlockscreen)"

apt_install i3lock imagemagick bc feh

# ── betterlockscreen ─────────────────────────────────────────────────────────
# Distributed as a single bash script; installed to /usr/local/bin.
if has_cmd betterlockscreen; then
    log_ok "betterlockscreen already installed"
else
    log_info "Installing betterlockscreen..."

    # betterlockscreen is a bash script — no compiled assets are attached to
    # releases. Resolve the latest tag and fetch the raw script at that ref.
    local_tag=$(curl -sf "https://api.github.com/repos/betterlockscreen/betterlockscreen/releases/latest" \
        | grep '"tag_name"' | cut -d'"' -f4)

    # Fall back to "main" if the API call fails
    local_ref="${local_tag:-main}"

    TMP=$(mktemp /tmp/bls_XXXXXX.sh)
    DL_URL="https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/${local_ref}/betterlockscreen"
    if curl -fsSL -o "$TMP" "$DL_URL"; then
        sudo install -Dm755 "$TMP" /usr/local/bin/betterlockscreen
        rm -f "$TMP"
        log_ok "betterlockscreen ${local_ref} installed"
    else
        rm -f "$TMP"
        log_warn "Failed to download betterlockscreen. Lock screen will not work."
    fi
fi
