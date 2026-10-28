#!/usr/bin/env bash
## Module 12 – System utilities
## maim, xclip, xdotool, light (brightness), wmname, imagemagick, xbacklight,
## pastel, xcolor (via cargo), ksuperkey (from source).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "System Utilities"

# ── Packaged utilities ────────────────────────────────────────────────────────
apt_install \
    maim \
    xclip \
    xdotool \
    light \
    imagemagick \
    xbacklight \
    wmctrl \
    curl \
    git \
    build-essential \
    pkg-config \
    libx11-dev \
    libx11-xcb-dev \
    libxcb1-dev \
    libxi-dev \
    libxtst-dev \
    libxcursor-dev \
    libxinerama-dev \
    libxrandr-dev \
    libnotify-bin

# Add user to video group so `light` can adjust brightness without sudo
_cur_user=$(whoami)
if ! groups "$_cur_user" | grep -qw video; then
    sudo usermod -aG video "$_cur_user"
    log_ok "Added $_cur_user to video group (logout required to take effect)"
fi

# ── ksuperkey (from source) ──────────────────────────────────────────────────
# Lets Super_L open the Rofi launcher (mapped as Alt_L|F1 in keybindings).
if has_cmd ksuperkey; then
    log_ok "ksuperkey already installed"
else
    log_info "Building ksuperkey from source..."
    TMP=$(mktemp -d)
    git clone --depth=1 https://github.com/hanschen/ksuperkey "$TMP/ksuperkey"
    make -C "$TMP/ksuperkey"
    sudo install -Dm755 "$TMP/ksuperkey/ksuperkey" /usr/local/bin/ksuperkey
    rm -rf "$TMP"
    log_ok "ksuperkey installed"
fi

# ── Rust + cargo (needed for xcolor & pastel) ────────────────────────────────
if ! has_cmd cargo; then
    log_info "Installing Rust toolchain (needed for xcolor and pastel)..."
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
    log_ok "Rust/cargo installed"
else
    log_ok "cargo already installed"
    # Ensure cargo env is loaded for subsequent installs
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
fi

# Ensure cargo is in PATH for this session
export PATH="$HOME/.cargo/bin:$PATH"

# ── xcolor (color picker used by i3_colorpicker) ────────────────────────────
if has_cmd xcolor; then
    log_ok "xcolor already installed"
else
    log_info "Installing xcolor via cargo..."
    cargo install xcolor && log_ok "xcolor installed" || log_warn "xcolor build failed – color picker (Super+p) will not work"
fi

# ── pastel (color manipulation, optional theming tool) ───────────────────────
if has_cmd pastel; then
    log_ok "pastel already installed"
else
    log_info "Installing pastel via cargo..."
    cargo install pastel && log_ok "pastel installed" || log_warn "pastel build failed – not required for core functionality"
fi

# Persist cargo bin path for future shells
PROFILE="$HOME/.bash_profile"
if ! grep -q 'cargo/bin' "$PROFILE" 2>/dev/null; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$PROFILE"
fi
