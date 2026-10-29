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
bash ~/ledot/install.sh            # full: bootstrap → CLI → [desktop] → [carbon] → dotfiles → second-brain → syncthing → [R packages]
bash ~/ledot/install.sh server     # headless: bootstrap → CLI → dotfiles → [R packages]
bash ~/ledot/install.sh dev web    # specific steps
bash ~/ledot/install.sh --list     # all steps
bash ~/ledot/install.sh --state    # what was installed outside apt/flatpak, from where, which version
```

Installs that apt/flatpak don't track (tarballs, curl installers, npm, pipx, conda, git clones, fonts) are logged to `$XDG_STATE_HOME/ledot/installs.tsv` (`name  source  version  date`). Tools a step finds already installed are logged as `detected`, so re-running a step on an existing machine fills in the log.

## Steps

| Step | Installs | Extras |
|---|---|---|
| `bootstrap` | | SSH key → GitHub, git identity |
| **CLI** | | |
| `minimal` | `minimal.list` | GitHub CLI repo, timezone |
| `network` | `network.list` | Tailscale repo, vpn-slice, VPN password in pass |
| `files` | `files.list` | |
| `dev` | `dev.list` | NodeSource repo, Docker (`bin/docker_install.sh`), Claude Code + skills, Gemini CLI, Antigravity, Miniconda + `tools` env (`python.libs`), radian, fabric, Singularity |
| `tools` | `tools.list` | |
| **Desktop** | | |
| `desktop` | `desktop.list` | Hyprland PPA (incl. hyprsunset night light), Nerd Fonts, Zafiro + Qogir themes |
| `greeter` | — | greetd + tuigreet on tty1; quiet boot/kernel console so nothing prints over the login |
| `display` | `display.list` | |
| `audio` | `audio.list` | |
| `bluetooth` | `bluetooth.list` | `/etc/bluetooth` mode 555 |
| `media` | `media.list`, `media.flatpak` | |
| `web` | `web.list` | Brave + Mozilla repos, browser logins, Tor Browser |
| `system` | `system.list` | upower enabled at boot |
| `apps` | `apps.list`, `apps.flatpak` | FUTO Notes repo, Thunar as default folder handler |
| `firewall` | ufw | resets ufw to deny-all-incoming + allowlist: ssh on tailscale0 only, tailscale 41641/udp, mDNS, Syncthing 22000 + 21027/udp; silent IGMP drop |
| **Device** | | |
| `carbon` | `carbon.list` | ThinkPad X1 Carbon 5th gen only (auto-detected from DMI): coretemp/RAPL early load for thermald, `initcall_blacklist=intel_uncore_init` (resource sanity warning), optional SD reader blacklist, optional ModemManager off (no SIM) |
| **After packages** | | |
| `dotfiles` | | symlinks from `config/dotfiles.state`, ~/utils repo, /etc/hosts (`dotfiles.sh --links`: symlinks only) |
| `second-brain` | | Obsidian, `second-brain/setup.sh` |
| `syncthing` | — | data partition mount (fstab by UUID), `~/<dir> → /data/drive/<dir>` links, Syncthing in Docker (`config/syncthing/compose.yml`; ports opened by `firewall`); removes the apt package/user service |
| `r` | `r-build.list`, `r.libs` | R packages; runs last and asks first (default **no**) — slow to build |

Shared helpers (colors, `confirm`, `install_list`, `install_flatpaks`, `confirm_no`, `pipx_install`, `track_install`, `track_detected`) live in `lib/common.sh`.
