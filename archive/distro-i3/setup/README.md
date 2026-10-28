# Archcraft i3wm → Ubuntu 24.04 Setup

Replicates the [Archcraft i3wm](https://github.com/archcraft-os/archcraft-i3wm) desktop environment on a clean **Ubuntu 24.04 Server** install (bare CLI, no GUI). The result is a fully functional i3 tiling WM with Polybar, Rofi, Dunst, Alacritty, Kitty, and all supporting tools — appearance and keybindings matching Archcraft as closely as possible.

---

## Prerequisites

- **Ubuntu 24.04** (server or minimal desktop)
- A regular user account with `sudo` privileges
- Internet access
- This repo cloned alongside `archcraft-i3wm/`:

```
distro/
├── archcraft-i3wm/   ← official archcraft config (cloned from GitHub)
└── setup/            ← these scripts
```

---

## Quick Start

```bash
cd ~/ledot/distro/
# git clone https://github.com/archcraft-os/archcraft-i3wm ~/ledot/distro/archcraft-i3wm
gh repo clone https://github.com/archcraft-os/archcraft-i3wm ~/ledot/distro/archcraft-i3wm

cd setup/
./setup.sh
```

After the script finishes:

1. **Log out** and log back in (picks up group membership changes for brightness control).
2. Run `startx` to launch i3.

To run a single module:

```bash
./setup.sh 06_fonts
```

To run a subset of modules in order:

```bash
./setup.sh 06_fonts 08_terminal 14_dotfiles
```

---

## File Structure

```
setup/
├── setup.sh              # Main orchestrator
├── lib/
│   └── common.sh         # Shared logging helpers and utility functions
└── modules/
    ├── 00_preflight.sh
    ├── 01_repos.sh
    ├── 02_xorg.sh
    ├── 03_wm.sh
    ├── 04_polybar.sh
    ├── 05_rofi.sh
    ├── 06_fonts.sh
    ├── 07_audio.sh
    ├── 08_terminal.sh
    ├── 09_apps.sh
    ├── 10_media.sh
    ├── 11_network.sh
    ├── 12_utils.sh
    ├── 13_lockscreen.sh
    └── 14_dotfiles.sh
```

All modules are **idempotent**: safe to run more than once.

---

## Modules

### `00_preflight` — Sanity Checks

Validates the environment before anything is installed.

- Aborts if run as root (the script calls `sudo` internally where needed)
- Warns if the OS is not Ubuntu 24.04
- Confirms `sudo` access
- Checks internet connectivity
- Warns if less than 4 GB of disk space is free

---

### `01_repos` — APT Repositories

Prepares the package manager.

- Enables the `universe` repository (required for most tools)
- Runs `apt update` and `apt upgrade`

---

### `02_xorg` — X Server & Session

Installs the display server and sets up the session entry point.

**Packages:** `xorg`, `xinit`, `x11-xserver-utils`, `x11-utils`, `x11-apps`, `xdg-user-dirs`

**Files created:**

| File | Purpose |
|---|---|
| `~/.xinitrc` | Merges Xresources, then `exec i3` |
| `~/.bash_profile` | Auto-runs `startx` when logging into tty1 |

After setup, logging into the server console on tty1 will automatically start the X session and i3.

---

### `03_wm` — Window Manager Core

Installs the window manager and all visual infrastructure.

**Packages:** `i3`, `i3status`, `picom`, `dunst`, `hsetroot`, `xsettingsd`, `xfce4-power-manager`, `policykit-1-gnome`

Also auto-detects the polkit agent binary path and writes it to `/tmp/ubuntu_rice_polkit_bin` for use by the dotfiles module. On Ubuntu 24.04 the expected path is:

```
/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1
```

Fallback locations checked if the primary path is missing:

```
/usr/libexec/polkit-gnome-authentication-agent-1
/usr/lib/x86_64-linux-gnu/libexec/polkit-gnome-authentication-agent-1
/usr/lib/xfce4/polkit-gnome-authentication-agent-1
```

---

### `04_polybar` — Status Bar

**Packages:** `polybar`, `upower`

`upower` is required by `theme/polybar.sh` to detect battery and AC adapter names for the Polybar modules.

---

### `05_rofi` — Application Launcher

**Packages:** `rofi`

Used by all `rofi_*` applet scripts (launcher, runner, powermenu, windows, music, bluetooth, screenshot, network, asroot).

---

### `06_fonts` — Nerd Fonts

Downloads and installs the three Nerd Fonts required by the i3 theme and Polybar config:

| Font | Used by |
|---|---|
| **JetBrainsMono Nerd Font** | i3 window titles (`font pango:JetBrainsMono Nerd Font 10`) |
| **Symbols Nerd Font** | Polybar icons (font-1, font-2 in `config.ini`) |
| **Iosevka Nerd Font** | Polybar accent labels (font-3 in `config.ini`) |
| **archcraft** | Polybar menu button glyph (font-4 in `config.ini`) |

Fonts are installed to `~/.local/share/fonts/NerdFonts/`. The latest release is resolved automatically via the GitHub API.

> **Note:** The `archcraft` icon font provides the Archcraft logo on the Polybar menu button. If the download fails, the button shows a box glyph — all functionality still works.

---

### `07_audio` — Audio Stack

Ubuntu 24.04 Server ships without audio. This module installs PipeWire with PulseAudio compatibility so `pulsemixer` (used by `i3_volume`) works out of the box.

**Packages:** `pipewire`, `pipewire-pulse`, `pipewire-audio`, `wireplumber`, `pulsemixer`, `pavucontrol`, `alsa-utils`

PipeWire user services (`pipewire`, `pipewire-pulse`, `wireplumber`) are enabled via `systemctl --user`. If no user session is active yet, they will start automatically on next login.

---

### `08_terminal` — Terminal Emulators

**Packages:** `alacritty`, `kitty`

| Terminal | Keybinding |
|---|---|
| Alacritty | `Super+Return` (normal), `Super+Shift+Return` (floating), `Super+Alt+Return` (fullscreen) |
| Kitty | `Alt+Ctrl+T` |

Config files for both are deployed from `archcraft-i3wm/files/` by the dotfiles module.

---

### `09_apps` — GUI Applications

**Packages:** `thunar`, `thunar-archive-plugin`, `thunar-volman`, `geany`, `geany-plugins`, `firefox`, `viewnior`, `yad`, `file-roller`, `tumbler`

| App | Keybinding |
|---|---|
| Thunar (file manager) | `Super+Shift+F` |
| Geany (text editor) | `Super+Shift+E` |
| Firefox (browser) | `Super+Shift+W` |

---

### `10_media` — Media Tools

**Packages:** `mpd`, `mpc`, `ffmpeg`

A minimal MPD configuration is created at `~/.config/mpd/mpd.conf` (using PipeWire output) if one does not already exist.

| Tool | Role |
|---|---|
| MPD | Music daemon, started by `i3_autostart` |
| MPC | CLI client; used by Polybar MPD module and media key bindings |
| FFmpeg | Screen recording (used by rofi screenshot applet) |

---

### `11_network` — Networking

**Packages:** `network-manager`, `network-manager-gnome`, `network-manager-openvpn`, `bluez`, `bluez-tools`, `blueman`

Also clones and installs **[networkmanager-dmenu](https://github.com/firecat53/networkmanager-dmenu)** — the Rofi-based network manager frontend used by the `network_menu` script (bound to `Super+N`).

A default config is written to `~/.config/networkmanager-dmenu/config.ini` that points `dmenu_command` at `rofi -dmenu`.

NetworkManager is enabled as a systemd service. On server installs that default to `systemd-networkd`, this module overrides to NetworkManager so nm-applet and networkmanager-dmenu work.

---

### `12_utils` — System Utilities

**Packages (apt):** `maim`, `xclip`, `xdotool`, `light`, `imagemagick`, `xbacklight`, `wmctrl`, `curl`, `git`, `build-essential`, `libx11-dev`, `libxi-dev`, `libnotify-bin`

**Built from source:**

- **[ksuperkey](https://github.com/hanschen/ksuperkey)** — remaps `Super_L`/`Super_R` to `Alt_L|F1`, allowing the Rofi launcher to open on a bare Super key press. Requires `libx11-dev` and `libxi-dev`.

**Installed via Cargo (Rust):**

- **[xcolor](https://github.com/Soft/xcolor)** — X11 color picker used by `i3_colorpicker` (`Super+P`).
- **[pastel](https://github.com/sharkdp/pastel)** — color manipulation CLI used by Archcraft theming tools.

If Rust/cargo is not present, it is installed to `~/.cargo/` via `rustup`. The cargo bin path is appended to `~/.bash_profile`.

The current user is added to the `video` group so `light` can control backlight brightness without `sudo`. **A logout/login is required for this to take effect.**

---

### `13_lockscreen` — Lock Screen

**Packages:** `i3lock`, `imagemagick`, `bc`, `feh`

Downloads the latest **[betterlockscreen](https://github.com/betterlockscreen/betterlockscreen)** binary release from GitHub and installs it to `/usr/local/bin/`. Betterlockscreen wraps `i3lock` with blur/dim/pixelate effects.

Bound to `Alt+Ctrl+L` in the keybindings config.

---

### `14_dotfiles` — Deploy Configuration

The core of the migration. Copies `archcraft-i3wm/files/` to `~/.config/i3/` and applies all patches needed to make the Archcraft scripts work on Ubuntu.

#### What gets deployed

```
~/.config/i3/
├── config                  # i3 main config (includes config.d/*)
├── config.d/
│   ├── 01_theme.conf       # fonts, borders, gaps, colors
│   ├── 02_keybindings.conf # all key/mouse bindings
│   ├── 03_mousebindings.conf
│   ├── 04_modes.conf       # resize mode
│   └── 05_rules.conf       # per-window rules
├── alacritty/              # Alacritty config (theme, fonts, colors)
├── kitty/                  # Kitty config
├── dunstrc                 # Dunst notification style
├── picom.conf              # Picom compositor config
├── xsettingsd              # GTK/Qt theme settings daemon config
├── scripts/                # i3_*, rofi_*, network_menu
├── theme/
│   ├── polybar.sh          # hardware detection + bar launcher
│   ├── polybar/            # Polybar config (config.ini, colors, modules, decor)
│   ├── rofi/               # Rofi themes (.rasi)
│   ├── system.ini          # hardware variables for Polybar modules
│   └── wallpaper           # desktop background
└── i3status/               # fallback i3status config
```

#### Ubuntu compatibility patches

| Archcraft assumption | What the module does |
|---|---|
| `/usr/lib/xfce-polkit/xfce-polkit` in `i3_autostart` | Auto-detects the correct `polkit-gnome` binary path and patches the script with `sed` |
| `/usr/share/archcraft/icons/dunst/*.png` in volume/brightness/screenshot scripts | Creates `/usr/share/archcraft/icons/dunst/`, populates it with symlinks from `hicolor`/`Adwaita` system theme; falls back to ImageMagick-generated placeholder PNGs |
| `theme/wallpaper` not included in repo | Copies first available wallpaper from `/usr/share/backgrounds/`; if none found, generates a dark gradient (`#1e222a → #282c34`) with ImageMagick |
| `theme/system.ini` default values (amdgpu, wlan0) | Runs hardware detection (`light -L`, `upower -e`, `ip link`) and writes correct values before first Polybar launch |
| `viewnior` called in `i3_screenshot` | Patches script to use `eog` if `viewnior` is absent |

#### Icon mapping (Archcraft → freedesktop)

| Archcraft icon | Freedesktop icon |
|---|---|
| `volume-mute.png` | `audio-volume-muted` |
| `volume-low.png` | `audio-volume-low` |
| `volume-mid.png` | `audio-volume-medium` |
| `volume-high.png` | `audio-volume-high` |
| `microphone.png` | `audio-input-microphone` |
| `microphone-mute.png` | `audio-input-microphone-muted` |
| `picture.png` | `image-x-generic` |
| `timer.png` | `preferences-system-time` |
| `brightness-*.png` | `display-brightness-medium` / `video-display` |

---

## Keybindings Reference

All bindings are defined in `~/.config/i3/config.d/02_keybindings.conf`. `$MOD` = Super, `$ALT` = Alt.

### Applications

| Binding | Action |
|---|---|
| `Super+Return` | Open Alacritty (tiled) |
| `Super+Shift+Return` | Open Alacritty (floating) |
| `Super+Alt+Return` | Open Alacritty (fullscreen) |
| `Alt+Ctrl+T` | Open Kitty |
| `Super+Shift+F` | Thunar (file manager) |
| `Super+Shift+E` | Geany (text editor) |
| `Super+Shift+W` | Firefox |
| `Alt+Ctrl+V` | Vim in Alacritty |
| `Alt+Ctrl+R` | Ranger in Alacritty |
| `Alt+Ctrl+H` | Htop in Alacritty |
| `Alt+Ctrl+M` | Music player (ncmpcpp) |

### Rofi Applets

| Binding | Action |
|---|---|
| `Alt+F1` | App launcher |
| `Alt+F2` | Command runner |
| `Super+N` | Network menu |
| `Super+X` | Power menu |
| `Super+W` | Window switcher |
| `Super+M` | Music control (MPD) |
| `Super+R` | Run as root |
| `Super+S` | Screenshot menu |

### System Controls

| Binding | Action |
|---|---|
| `Print` | Screenshot now |
| `Ctrl+Print` | Screenshot in 5s |
| `Shift+Print` | Screenshot in 10s |
| `Ctrl+Shift+Print` | Screenshot active window |
| `Super+Print` | Screenshot area |
| `Super+P` | Color picker (xcolor) |
| `Alt+Ctrl+L` | Lock screen (betterlockscreen) |
| `XF86AudioRaiseVolume` | Volume +5% |
| `XF86AudioLowerVolume` | Volume -5% |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioMicMute` | Toggle mic mute |
| `XF86MonBrightnessUp` | Brightness +10% |
| `XF86MonBrightnessDown` | Brightness -10% |

### Window Management

| Binding | Action |
|---|---|
| `Super+Q` / `Super+C` | Close window |
| `Super+H` | Split horizontal |
| `Super+V` | Split vertical |
| `Super+F` | Toggle fullscreen |
| `Super+Space` | Toggle floating |
| `Super+Tab` | Focus next window |
| `Super+←/↓/↑/→` | Focus in direction |
| `Super+Shift+←/↓/↑/→` | Move window |
| `Super+Alt+←/↓/↑/→` | Resize window |
| `Super+1–0` | Switch to workspace 1–10 |
| `Super+Shift+1–0` | Move window to workspace |
| `Super+Minus` | Send to scratchpad |
| `Super+Shift+Minus` | Show scratchpad |
| `Ctrl+Shift+R` | Restart i3 |
| `Super+Shift+C` | Reload i3 config |
| `Super+Shift+Q` | Exit i3 |

---

## Post-Install Notes

### Brightness control

`light` requires membership in the `video` group. The setup script adds you automatically, but you must log out and back in for it to take effect. If brightness keys still don't work after relogin:

```bash
sudo chmod +s $(which light)
```

### Wallpaper

The wallpaper is stored at `~/.config/i3/theme/wallpaper`. Replace it with any image:

```bash
cp /path/to/your/image.jpg ~/.config/i3/theme/wallpaper
# Then reload i3:
i3-msg restart
```

### Polybar hardware variables

If Polybar modules show wrong data (e.g. wrong network interface), edit `~/.config/i3/theme/system.ini`:

```ini
[system]
sys_adapter          = AC0          # ls /sys/class/power_supply/
sys_battery          = BAT0         # ls /sys/class/power_supply/
sys_graphics_card    = intel_bl0    # ls /sys/class/backlight/
sys_network_interface = eth0        # ip link | awk '/state UP/'
```

Then remove the sentinel file and restart Polybar:

```bash
rm ~/.config/i3/theme/.system
i3-msg restart
```

### MPD / music

Add audio files to `~/Music/` and update the database:

```bash
mpc update
mpc ls | mpc add   # add all tracks
mpc play
```

### Archcraft icon font

The Polybar menu button uses the `archcraft` glyph font. If it showed a box on install:

```bash
# Download archcraft.ttf manually and place it:
cp archcraft.ttf ~/.local/share/fonts/NerdFonts/
fc-cache -f ~/.local/share/fonts/NerdFonts/
i3-msg restart
```

---

## Troubleshooting

**Black screen after `startx`**
Check `~/.local/share/xorg/Xorg.0.log` or `/var/log/Xorg.0.log` for errors. Ensure the `xorg` package is fully installed:
```bash
sudo apt install xorg --fix-broken
```

**Polybar doesn't start**
Run it manually to see errors:
```bash
polybar main --config=~/.config/i3/theme/polybar/config.ini 2>&1
```
Missing fonts are the most common cause. Rerun `./setup.sh 06_fonts`.

**Rofi applets show errors about missing scripts**
Ensure the scripts are executable:
```bash
chmod +x ~/.config/i3/scripts/*
```

**Volume keys do nothing**
Verify PipeWire is running:
```bash
systemctl --user status pipewire pipewire-pulse
```
If inactive, start them:
```bash
systemctl --user start pipewire pipewire-pulse wireplumber
```

**Lock screen (`Alt+Ctrl+L`) fails**
Check that `betterlockscreen` installed correctly:
```bash
which betterlockscreen && betterlockscreen --version
```
If missing, rerun `./setup.sh 13_lockscreen`.

**Network menu (`Super+N`) does nothing**
Verify `networkmanager_dmenu` is installed and NetworkManager is running:
```bash
which networkmanager_dmenu
systemctl status NetworkManager
```
