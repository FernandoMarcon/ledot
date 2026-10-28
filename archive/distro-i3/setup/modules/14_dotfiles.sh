#!/usr/bin/env bash
## Module 14 – Deploy dotfiles
## Copies the archcraft-i3wm config tree to ~/.config/i3/, then applies
## Ubuntu-specific patches to make every script work on this system.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "Deploying i3 Dotfiles"

I3_CFG="$HOME/.config/i3"
# REPO_DIR is exported by setup.sh; fall back to sibling directory
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/archcraft-i3wm}"
FILES_SRC="$REPO_DIR/files"

if [[ ! -d "$FILES_SRC" ]]; then
    log_error "Source not found: $FILES_SRC"
    exit 1
fi

# ── 1. Symlink config tree ────────────────────────────────────────────────────
mkdir -p "$(dirname "$I3_CFG")"
ln -sfn "$FILES_SRC" "$I3_CFG"
log_ok "Config symlinked: $I3_CFG → $FILES_SRC"

# Make all scripts executable
find "$I3_CFG/scripts" "$I3_CFG/theme" -type f \( -name "*.sh" -o \
    -name "i3_*" -o -name "rofi_*" -o -name "network_menu" \) \
    -exec chmod +x {} +
log_ok "Scripts marked executable"

# ── 2. Patch i3_autostart – fix Archcraft-specific paths ─────────────────────
AUTOSTART="$I3_CFG/scripts/i3_autostart"

# 2a. Polkit agent
POLKIT_BIN=""
for candidate in \
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 \
    /usr/libexec/polkit-gnome-authentication-agent-1 \
    /usr/lib/x86_64-linux-gnu/libexec/polkit-gnome-authentication-agent-1; do
    if [[ -x "$candidate" ]]; then
        POLKIT_BIN="$candidate"
        break
    fi
done

if [[ -n "$POLKIT_BIN" && -x "$POLKIT_BIN" ]]; then
    # Replace the xfce-polkit line with the detected binary
    sed -i \
        "s|/usr/lib/xfce-polkit/xfce-polkit|$POLKIT_BIN|g" \
        "$AUTOSTART"
    log_ok "Polkit agent path patched → $POLKIT_BIN"
else
    log_warn "No polkit agent found — removing polkit block from i3_autostart"
    sed -i '/xfce-polkit/d' "$AUTOSTART"
fi

# ── 3. Patch icon path in scripts ────────────────────────────────────────────
# Archcraft scripts reference /usr/share/archcraft/icons/dunst/.
# We create that directory and populate it with system icon symlinks.
ARCH_ICON_DIR="/usr/share/archcraft/icons/dunst"
sudo mkdir -p "$ARCH_ICON_DIR"

# Map archcraft icon names → freedesktop icon names (Papirus / hicolor theme)
declare -A ICON_MAP=(
    [volume-mute]="audio-volume-muted"
    [volume-low]="audio-volume-low"
    [volume-mid]="audio-volume-medium"
    [volume-high]="audio-volume-high"
    [microphone]="audio-input-microphone"
    [microphone-mute]="audio-input-microphone-muted"
    [picture]="image-x-generic"
    [timer]="preferences-system-time"
)

find_system_icon() {
    local name="$1"
    # Search common theme dirs, prefer PNG over SVG
    for size in 48 32 24 22; do
        for theme_dir in /usr/share/icons/hicolor /usr/share/icons/Adwaita \
                         /usr/share/icons/gnome /usr/share/icons/Papirus; do
            local found
            found=$(find "${theme_dir}/${size}x${size}" -name "${name}.png" 2>/dev/null | head -1)
            [[ -n "$found" ]] && { echo "$found"; return; }
        done
    done
    # SVG fallback
    for theme_dir in /usr/share/icons/hicolor /usr/share/icons/Adwaita \
                     /usr/share/icons/gnome /usr/share/icons/Papirus; do
        local found
        found=$(find "${theme_dir}" -name "${name}.svg" 2>/dev/null | head -1)
        [[ -n "$found" ]] && { echo "$found"; return; }
    done
    echo ""
}

for arch_name in "${!ICON_MAP[@]}"; do
    fd_name="${ICON_MAP[$arch_name]}"
    src=$(find_system_icon "$fd_name")
    dest="$ARCH_ICON_DIR/${arch_name}.png"
    if [[ -n "$src" && ! -e "$dest" ]]; then
        sudo ln -sf "$src" "$dest"
    elif [[ -z "$src" && ! -e "$dest" ]]; then
        _tmp=$(mktemp /tmp/icon_XXXXXX.png)
        if convert -size 32x32 xc:'#61afef' "$_tmp" 2>/dev/null; then
            sudo mv "$_tmp" "$dest"
        else
            rm -f "$_tmp"
            sudo touch "$dest"
        fi
    fi
done

# Brightness icons (brightness-20 through brightness-100)
for level in 20 40 60 80 100; do
    dest="$ARCH_ICON_DIR/brightness-${level}.png"
    if [[ ! -e "$dest" ]]; then
        src=$(find_system_icon "display-brightness-medium")
        [[ -z "$src" ]] && src=$(find_system_icon "video-display")
        if [[ -n "$src" ]]; then
            sudo ln -sf "$src" "$dest"
        else
            _tmp=$(mktemp /tmp/icon_XXXXXX.png)
            if convert -size 32x32 xc:'#e5c07b' "$_tmp" 2>/dev/null; then
                sudo mv "$_tmp" "$dest"
            else
                rm -f "$_tmp"
                sudo touch "$dest"
            fi
        fi
    fi
done

log_ok "Archcraft dunst icons populated at $ARCH_ICON_DIR"

# ── 4. Wallpaper ─────────────────────────────────────────────────────────────
WALLPAPER="$I3_CFG/theme/wallpaper"
mkdir -p "$(dirname "$WALLPAPER")"
if [[ ! -f "$WALLPAPER" ]]; then
    # Try system backgrounds first
    SYS_WP=$(find /usr/share/backgrounds -name "*.jpg" -o -name "*.png" 2>/dev/null | head -1 || true)
    if [[ -n "$SYS_WP" ]]; then
        cp "$SYS_WP" "$WALLPAPER"
        log_ok "Wallpaper: copied $SYS_WP"
    else
        # Generate a simple dark gradient with ImageMagick
        _wp_tmp=$(mktemp /tmp/wallpaper_XXXXXX.png)
        if has_cmd magick; then
            magick -size 1920x1080 gradient:'#1e222a-#282c34' "$_wp_tmp"
            mv "$_wp_tmp" "$WALLPAPER"
            log_ok "Wallpaper: generated gradient"
        elif has_cmd convert; then
            convert -size 1920x1080 gradient:'#1e222a-#282c34' "$_wp_tmp"
            mv "$_wp_tmp" "$WALLPAPER"
            log_ok "Wallpaper: generated gradient"
        else
            rm -f "$_wp_tmp"
            log_warn "No wallpaper found and ImageMagick unavailable. Set '$WALLPAPER' manually."
        fi
    fi
else
    log_ok "Wallpaper already present"
fi

# ── 5. Patch viewnior path in screenshot script (Ubuntu uses eog if viewnior absent) ──
if ! has_cmd viewnior && has_cmd eog; then
    sed -i 's/viewnior /eog /g' "$I3_CFG/scripts/i3_screenshot"
    log_info "Screenshot viewer patched: viewnior → eog"
fi

# ── 6. Generate theme/system.ini with detected hardware values ───────────────
SYSTEM_INI="$I3_CFG/theme/system.ini"
# These sed substitutions mirror what polybar.sh does on first run.
# We run it eagerly so Polybar starts correctly without a .system file check.

CARD=$(light -L 2>/dev/null | grep 'backlight' | head -n1 | cut -d'/' -f3 || echo "")
BATTERY=$(upower -e 2>/dev/null | grep -i bat | xargs -I{} upower -i {} 2>/dev/null | \
    grep 'native-path' | head -1 | awk '{print $2}' || echo "")
ADAPTER=$(upower -e 2>/dev/null | grep -i ac | xargs -I{} upower -i {} 2>/dev/null | \
    grep 'native-path' | head -1 | awk '{print $2}' || echo "")
IFACE=$(ip link 2>/dev/null | awk '/state UP/ {gsub(/:/, ""); print $2}' | head -1 || echo "")

[[ -n "$CARD"    ]] && sed -i "s/sys_graphics_card = .*/sys_graphics_card = $CARD/"       "$SYSTEM_INI"
[[ -n "$BATTERY" ]] && sed -i "s/sys_battery = .*/sys_battery = $BATTERY/"                "$SYSTEM_INI"
[[ -n "$ADAPTER" ]] && sed -i "s/sys_adapter = .*/sys_adapter = $ADAPTER/"                "$SYSTEM_INI"
[[ -n "$IFACE"   ]] && sed -i "s/sys_network_interface = .*/sys_network_interface = $IFACE/" "$SYSTEM_INI"

log_ok "system.ini values: card=${CARD:-n/a} battery=${BATTERY:-n/a} adapter=${ADAPTER:-n/a} iface=${IFACE:-n/a}"

# Force polybar.sh to re-detect on next start (remove .system sentinel)
rm -f "$I3_CFG/theme/.system"

log_ok "Dotfiles deployed successfully"
