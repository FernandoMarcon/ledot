# Testing Environment

Run the Ubuntu i3wm setup inside a Docker container with a live graphical display — no separate machine needed.

## How it works

A Docker container (`ubuntu:24.04`) has the entire `distro/` repo mounted as a read-write volume. Inside the container you run setup modules one at a time with the interactive step-runner. The graphical output (i3, Polybar, Rofi, etc.) appears on your host desktop via one of two display methods:

```
┌─────────────────────────────────────────────────────────────────┐
│  Host (Arch, running X on :0)                                   │
│                                                                 │
│  ┌────────────────────────────────┐                             │
│  │  Xephyr :10  ← nested display  │  ← Xephyr mode (default)    │
│  │                                │                             │
│  │   ┌──── Docker container ────┐ │                             │
│  │   │  Ubuntu 24.04            │ │                             │
│  │   │  DISPLAY=:10             │ │                             │
│  │   │  i3 / polybar / rofi     │ │                             │
│  │   └──────────────────────────┘ │                             │
│  └────────────────────────────────┘                             │
│                                                                 │
│  OR: browser → http://localhost:6080  ← VNC mode (no X needed)  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

```bash
# Docker (Arch)
sudo pacman -S docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER   # then re-login

# Xephyr (already installed on Archcraft)
sudo pacman -S xorg-server-xephyr   # if missing
```

---

## Quick Start — Xephyr mode

This is the recommended mode: i3 runs in a window on your current desktop.

```bash
cd ~/distro/testing
./scripts/launch.sh           # builds image, starts Xephyr, drops into container
```

Inside the container:

```bash
~/distro/testing/scripts/step-runner.sh
```

---

## Quick Start — VNC mode

Fully self-contained. No host X server needed. Useful if testing from a headless machine or SSH session.

```bash
cd ~/distro/testing
./scripts/launch.sh vnc
```

Then open **http://localhost:6080/vnc.html** in a browser.

Inside the container (via the noVNC browser terminal or a separate `docker exec`):

```bash
~/distro/testing/scripts/step-runner.sh
```

---

## File Structure

```
testing/
├── Dockerfile                # Ubuntu 24.04 + Xvfb + x11vnc + noVNC + sudo user
├── docker-compose.yml        # Alternative to launch.sh
├── .dockerignore
└── scripts/
    ├── launch.sh             # Host-side: build, start, checkpoint
    ├── container-init.sh     # Container entrypoint: sets up display, prints banner
    └── step-runner.sh        # Interactive module runner (run inside container)
```

---

## launch.sh reference

```bash
./scripts/launch.sh [command]
```

| Command | What it does |
|---|---|
| `xephyr` | **(default)** Start Xephyr on `:10`, start container wired to it |
| `vnc` | Start container with Xvfb + x11vnc + noVNC on ports 5900/6080 |
| `build` | Rebuild the Docker image (force fresh layer cache) |
| `exec` | Open a second shell in a running container |
| `checkpoint [tag]` | `docker commit` current container state as a restore point |
| `clean` | Stop and remove the container + image |

### Checkpoint / rollback workflow

```bash
# After several modules succeed, save the state:
./scripts/launch.sh checkpoint after-wm

# Later, restore from that point:
docker run -it --name ubuntu-i3-test ubuntu-i3-test:after-wm
```

---

## step-runner.sh reference

```bash
# Full walk-through (inside container)
~/distro/testing/scripts/step-runner.sh

# Start from a specific module
~/distro/testing/scripts/step-runner.sh 06_fonts

# Run from module index 06 onwards
~/distro/testing/scripts/step-runner.sh --from 06

# List all modules
~/distro/testing/scripts/step-runner.sh --list
```

### Keyboard controls during the walk-through

| Key | Action |
|---|---|
| `Enter` or `Y` | Run the current module |
| `s` | Skip this module |
| `r` | Run all remaining modules without prompting |
| `q` | Quit and print status summary |

After each module the runner prints a **smoke test** (checks key binaries exist) and a **"Try it out"** hint showing what you can launch to visually verify that module.

---

## Progressive testing walkthrough

Here is what to expect and verify at each major milestone.

### After `03_wm`

```bash
# Inside container — launch a minimal i3 session
i3 &
```

You should see an empty i3 workspace appear in the Xephyr window (or VNC). Press `Super+Return` — but Alacritty isn't installed yet, so i3 will show a startup error. That's expected.

### After `08_terminal`

Kill and relaunch i3:

```bash
killall i3 2>/dev/null; sleep 1; i3 &
```

Now `Super+Return` opens an Alacritty terminal inside the Xephyr window.

### After `14_dotfiles`

This is the full environment. Launch i3:

```bash
i3 &
```

What to verify:

| Feature | How to test |
|---|---|
| Window gaps & borders | Open 2+ terminals, observe gaps |
| Polybar | Should appear at the top of the Xephyr window |
| Rofi launcher | `Alt+F1` |
| Rofi power menu | `Super+X` |
| Volume keys | `XF86AudioRaiseVolume` (or `pactl set-sink-volume @DEFAULT_SINK@ +5%`) |
| Dunst notifications | `dunstify "test" "hello from dunst"` |
| Wallpaper | Should be visible on the desktop |
| Compositor | Transparency/shadow on floating windows (`Super+Space`) |
| Thunar | `Super+Shift+F` |
| Network menu | `Super+N` |
| Screenshot | `Print` key |

---

## docker compose alternative

Instead of `launch.sh`, you can use docker compose:

```bash
# Xephyr mode (start Xephyr manually first)
Xephyr :10 -screen 1280x800 -resizeable &
xhost +local:
docker compose --profile xephyr up

# VNC mode
docker compose --profile vnc up
```

---

## Troubleshooting

**`launch.sh` fails with "Xephyr not found"**

```bash
sudo pacman -S xorg-server-xephyr
```

**Xephyr window opens but is black / nothing appears**

The container hasn't launched i3 yet. Run the step-runner or start i3 manually:

```bash
docker exec -it ubuntu-i3-test bash -c "DISPLAY=:10 i3 &"
```

**"Cannot open display :10" inside container**

```bash
# On the host, allow local X connections:
xhost +local:
```

**noVNC page loads but shows "Disconnected"**

The VNC server may still be starting. Wait 2-3 seconds and refresh. Check inside the container:

```bash
docker exec ubuntu-i3-test ps aux | grep -E 'x11vnc|Xvfb'
```

**Module fails with "sudo: command not found"** or permission error

The Dockerfile installs `sudo` and grants passwordless access to user `tester`. If you see this, the image may be stale — rebuild:

```bash
./scripts/launch.sh clean
./scripts/launch.sh build
```

**`systemctl --user` fails for audio / PipeWire**

`systemd` user sessions don't run inside plain Docker containers. PipeWire services won't auto-start. Start them manually after module 07:

```bash
pipewire &
pipewire-pulse &
wireplumber &
```

**`pulsemixer` shows no sinks**

PipeWire isn't running yet (see above). Once started, retry.

**Fonts missing in Polybar (shows boxes)**

Nerd Fonts take a moment to register. Rebuild the font cache:

```bash
fc-cache -f ~/.local/share/fonts/NerdFonts/
```

Then restart i3: `Ctrl+Shift+R`



---
notes:

manually start i3 in docker:
   distro   docker exec -it ubuntu-i3-test bash -c "DISPLAY=:99 i3 &"

   distro docker exec ubuntu-i3-test ps aux |
grep i3
   distro docker exec ubuntu-i3-test which i3
/usr/bin/i3
   distro docker exec -d ubuntu-i3-test bash -
c "DISPLAY=:99 i3"

