# Dotfiles

Ubuntu 26.04 machine setup + dotfiles. Full details: [setup/README.md](setup/README.md).

## 1. Install / set up everything

On a fresh machine, get the repo first. The GitHub CLI device flow works without a browser: open `github.com/login/device` on your phone and enter the code it prints.

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install gh -y
gh auth login                                   # GitHub.com → HTTPS → Login with a web browser
gh repo clone FernandoMarcon/ledot ~/ledot
```

Then run the full setup (`bootstrap` creates the SSH key, adds it to GitHub and sets the git identity):

```bash
bash ~/ledot/install.sh              # this machine's profile: personal | server | work
bash ~/ledot/install.sh server       # headless: CLI steps + dotfiles + functions + data + [R]
bash ~/ledot/install.sh --profile    # show the profile (--profile <name> sets it)
```

The **profile** decides what runs. carbon is `personal` (everything). mentat, fremen and sardaukar are `server` (lean: no desktop, no second-brain). lgcm is `work`: it asks before every step, and never sets up Syncthing, `/data` or personal state. A new hostname is asked once.

The **`data`** step decides where Drive (`~/Documents`, `~/Projects`, …) lives, synced with mentat's `/data/drive`. It reuses an existing `/data`. On a new machine it offers: repartition into `/` | UPS | `/data`, a `/data/drive` folder on `/`, an sshfs mount of mentat's Drive (stationary machines), or `~/.drive`. See [setup/README.md](setup/README.md#where-drive-lives-data-step).

Every step is idempotent, so re-running is safe.

## 2. Install / set up a specific group

Each group is one script, `setup/<group>.sh`, installing `pkgs/<group>.list` (+ `.flatpak`) and its extras:

```bash
bash ~/ledot/install.sh web            # one group
bash ~/ledot/install.sh dev web media  # several, in the given order
bash ~/ledot/install.sh --list         # all groups
bash ~/ledot/install.sh --state        # what was installed outside apt/flatpak
```

## 3. Set up dotfiles

Symlinks `config/<item>` into `~/.config` (or `~`), backing up anything already there. Which items are on lives in [config/dotfiles.state](config/dotfiles.state) (`<item> yes|no`).

```bash
bash ~/ledot/setup/dotfiles.sh            # apply the state file (+ plugin installs, ~/utils, /etc/hosts)
bash ~/ledot/setup/dotfiles.sh --links    # symlinks only
bash ~/ledot/setup/dotfiles.sh nvim tmux  # activate specific items
```

Items: `aliases alacritty bashrc btop cava hypr kitty locales nvim profile quickshell ranger rofi tmux vim vimb waybar yazi` (+ `tools` for the ~/utils repo). Some install their plugin manager on activation: tmux → TPM, vim → Vundle, nvim → packer.nvim.

## 4. Setup items (install order)

| # | Group | What |
|---|---|---|
| 1 | `bootstrap` | SSH key, GitHub access, git identity |
| **CLI** | | |
| 2 | `minimal` | essentials for a working CLI system, timezone, locale |
| 3 | `network` | VPN, remote filesystems, Tailscale |
| 4 | `files` | yazi previews, archives, file utilities |
| 5 | `dev` | languages and dev tooling, Docker, Claude Code, Miniconda |
| 6 | `tools` | everyday handy tools, Bitwarden CLI |
| **Desktop** (skip on servers) | | |
| 7 | `desktop` | Hyprland desktop, fonts, themes |
| 8 | `display` | brightness, screenshots |
| 9 | `audio` | PipeWire stack, mixers, visualizer |
| 10 | `bluetooth` | bluetooth |
| 11 | `media` | players, downloaders, image tools |
| 12 | `web` | browsers, torrents |
| 13 | `system` | disks, power, monitoring |
| 14 | `apps` | office, remote desktop, file manager, Proton, LocalSend |
| 15 | `firewall` | ufw deny-all-incoming + allowlist |
| 16 | `greeter` | greetd + tuigreet login on tty1, replacing gdm3 (asks, default no) |
| **Device** | | |
| 17 | `carbon` | ThinkPad X1 Carbon 5th gen quirks (auto-detected) |
| **After packages** | | |
| 18 | `dotfiles` | config symlinks, ~/utils, /etc/hosts |
| 19 | `functions` | `functions/*` on PATH + their dependencies |
| 20 | `second-brain` | Second Brain workspace (Obsidian: `extra`) |
| 21 | `data` | where Drive lives (/data partition, /data/drive dir, sshfs to mentat, ~/.drive), `~/<dir>` links → `syncthing` |
| — | `syncthing` | Syncthing in Docker, `Drive` paired with mentat over ssh (run by `data`) |
| 22 | `r` | R packages (slow; asks, default no) |
| 23 | `extra` | optional tools menu: redundant with a default or for specific situations (Brave, Chromium, VLC, Okular, Obsidian, Inkscape, FreeCAD, ranger, coredump, …), grouped by step; tick to install, untick to remove |
| **Optional** (`install.sh <group>` only) | | |
| — | `nvim` | Neovim from `progs/` tarball → GitHub release → apt |
| — | `elegoo` | ElegooSlicer 3D printing slicer ([docs](docs/printers/elegoo-slicer.md)) |

## TO-DO
### NVIM/VIM
- vim -> nvim
- Add (, [, etc surrounding word
- Folding 
- File tree
- render-markdown (plugin)

### TMUX
- when new tab, load .env and activate conda prj env
- Floating terminal 
- Lazygit
- 

## Resources
### VIM/NVIM
#### vimrc
- [mikehaertl](https://gist.github.com/mikehaertl/1612035)
- https://www.youtube.com/watch?v=g1gyYttzxcI

### BASH
- https://www.youtube.com/watch?v=b3W7Ky_aaaY
- https://www.youtube.com/watch?v=D6HmEi9C5K8

### RANGER
- https://www.youtube.com/watch?v=L6Vu7WPkoJo
- https://www.youtube.com/watch?v=EyW6pRlWv6Q

### TMUX
- https://www.youtube.com/watch?v=7BP9iWiKx8Q

### I3WM

### DMENU
- https://www.youtube.com/watch?v=a2GWqF32U8Q
- https://www.youtube.com/watch?v=Dlj_SbE8zG4
- https://www.youtube.com/watch?v=R9m723tAurA

### VIMWIKI/MARKDOWN
- 
