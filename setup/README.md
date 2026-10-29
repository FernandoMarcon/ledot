# setup/ — machine setup (Ubuntu 26.04)

One script per package list: `setup/<name>.sh` installs `pkgs/<name>.list` (and `pkgs/<name>.flatpak` from Flathub) plus that theme's extra setup (apt repos, non-apt installs, config). Every script is idempotent and safe to re-run.

## First steps (by hand, fresh install)

```bash
# 1. Update the system
sudo apt update && sudo apt upgrade -y

# 2. Install and authenticate the GitHub CLI (device flow, no browser needed here)
sudo apt install gh -y
gh auth login        # GitHub.com → HTTPS → Login with a web browser
                     # open github.com/login/device on your phone, enter the code

# 3. Clone ledot
gh repo clone FernandoMarcon/ledot ~/ledot
# or: git clone https://github.com/FernandoMarcon/ledot.git ~/ledot
```

## Run

```bash
bash ~/ledot/install.sh            # full: bootstrap → CLI → [desktop] → dotfiles → second-brain → syncthing
bash ~/ledot/install.sh server     # headless: bootstrap → CLI → dotfiles
bash ~/ledot/install.sh dev web    # specific steps
bash ~/ledot/install.sh --list     # all steps
```

## Steps

| Step | Installs | Extras |
|---|---|---|
| `bootstrap` | | SSH key → GitHub, git identity |
| **CLI** | | |
| `minimal` | `minimal.list` | GitHub CLI repo, timezone |
| `network` | `network.list` | Tailscale repo, vpn-slice, VPN password in pass |
| `files` | `files.list` | |
| `dev` | `dev.list` | NodeSource repo, Docker (`bin/docker_install.sh`), Claude Code + skills, Gemini CLI, Antigravity, Miniconda + `tools` env (`python.libs`), R packages (`r-build.list`, `r.libs`), radian, fabric, Singularity |
| `tools` | `tools.list` | |
| **Desktop** | | |
| `desktop` | `desktop.list` | Hyprland PPA (incl. hyprsunset night light), Nerd Fonts, Zafiro + Qogir themes |
| `greeter` | — | greetd + tuigreet on tty1; quiet boot/kernel console so nothing prints over the login |
| `display` | `display.list` | |
| `audio` | `audio.list` | |
| `bluetooth` | `bluetooth.list` | |
| `media` | `media.list`, `media.flatpak` | |
| `web` | `web.list` | Brave + Mozilla repos, browser logins, Tor Browser, brotab |
| `system` | `system.list` | |
| `apps` | `apps.list`, `apps.flatpak` | FUTO Notes repo, Thunar as default folder handler |
| **After packages** | | |
| `dotfiles` | | symlinks from `config/dotfiles.state`, ~/utils repo, /etc/hosts (`dotfiles.sh --links`: symlinks only) |
| `second-brain` | | Obsidian, `second-brain/setup.sh` |
| `syncthing` | syncthing | data partition mount, `~/<dir> → /data/drive/<dir>` links, Syncthing repo + service |

Shared helpers (colors, `confirm`, `install_list`, `install_flatpaks`, `pipx_install`) live in `lib/common.sh`.
