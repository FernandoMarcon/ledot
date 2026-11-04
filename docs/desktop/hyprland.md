# Hyprland Installation (Ubuntu 24.04)

Hyprland is not in the Ubuntu 24.04 repos. Install it from the community PPA:

```bash
sudo add-apt-repository ppa:cppiber/hyprland
sudo apt update
sudo apt install hyprland xdg-desktop-portal-hyprland
```

## Default Apps

The default config (`hypr/hyprland.lua`) uses `kitty` as terminal (`SUPER+Q`) and `hyprlauncher` as app menu (`SUPER+R`).

```bash
sudo apt install kitty          # Ubuntu repos
sudo apt install hyprlauncher   # cppiber/hyprland PPA (add it first, see above)
```

## NVIDIA

Requires `nvidia_drm modeset=1` (already set by `nvidia-driver-580` in `/etc/modprobe.d/nvidia-graphics-drivers-kms.conf`). Check:

```bash
sudo cat /sys/module/nvidia_drm/parameters/modeset   # should print Y
```

NVIDIA env vars and `cursor.no_hardware_cursors` are set in `hypr/hyprland.lua`.

## Link Config

```bash
bash ~/ledot/setup/dotfiles.sh hypr   # ~/.config/hypr -> ~/ledot/config/hypr
```

Log out and pick the **Hyprland** session in the display manager.
