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
bash ~/ledot/install.sh            # this machine's profile (see below)
bash ~/ledot/install.sh server     # the server steps, whatever the profile
bash ~/ledot/install.sh dev web    # specific steps
bash ~/ledot/install.sh --profile  # show the profile; --profile <name> sets it
bash ~/ledot/install.sh --list     # all steps
bash ~/ledot/install.sh --state    # what was installed outside apt/flatpak, from where, which version
```

### Profiles

| Profile | Machines | `install.sh` runs |
|---|---|---|
| `personal` | carbon | bootstrap → CLI → [desktop → [greeter]] → [carbon] → dotfiles → functions → second-brain → data → [R] |
| `server` | mentat, fremen, sardaukar | bootstrap → CLI → dotfiles → functions → data → [R] (no desktop, no second-brain) |
| `work` | lgcm | asks before each step (default **no**); never greeter, data/Syncthing or second-brain; `dotfiles` asks per link and leaves `dotfiles.state` alone |

Known hostnames map to a profile (`KNOWN_PROFILES` in `lib/common.sh`); a new machine is asked once and the answer kept in `~/.local/state/ledot/profile`.

### Where Drive lives (`data` step)

Every machine except the work PC keeps `~/<dir>` (Documents, Images, Projects, …) as links into a Drive root synced with mentat's `/data/drive` (Syncthing folder `Drive`, simple versioning). The `data` step reuses what it finds: a mounted `/data`, a `/data` in fstab, an unmounted ext4 partition labelled `data` (a reinstall), or the layout saved in `~/.local/state/ledot/data-layout`. On a new machine it asks:

1. **Repartition into `/` | UPS | `/data`.** `/` is used + 20 %, rounded up to 5 GiB (at least 20 GiB). `/data` is 500 GiB if it fits, else 400, else 250 (the minimum), and you can change it at the prompt. The rest is left unallocated as the UPS reserve. When the space is already free (unpartitioned disk, or free extents in root's LVM VG), `/data` is created right away. When `/` must shrink, ext4 can only do that unmounted, so the step writes `/boot/efi/ledot/repartition.sh` to run from a live USB, and offers a temporary layout until then.
2. **`/data/drive` folder on `/`.** `/data` and `/data/drive` are owned by you, so you never need sudo for daily files.
3. **Mount `mentat:/data/drive` over sshfs.** For stationary LAN machines with small disks: no local copy and no Syncthing. It uses a root automount in fstab with your key, `reconnect` and `_netdev`.
4. **Dirs in home.** Drive lives at `~/.drive`, not `~` itself, because a lost `.stignore` would otherwise sync `~/.ssh` to every machine. This is the last resort.

The step recommends option 1 when it can run right away, option 3 for a desktop whose free space is smaller than mentat's Drive, and otherwise option 1 via live USB or option 2. Switching layouts later (`bash ~/ledot/setup/data.sh --choose`) moves your files to the new place and relinks `~`. Pairing with mentat is automatic over `ssh mentat`: both sides add each other's device and share `Drive`. When `Host mentat` or the key is missing, it offers to add the ssh entry, generate a key and run `ssh-copy-id`. On mentat itself, the step does nothing because mentat is the hub.

Installs that apt/flatpak don't track (tarballs, curl installers, npm, pipx, conda, git clones, fonts) are logged to `$XDG_STATE_HOME/ledot/installs.tsv` (`name  source  version  date`). Tools a step finds already installed are logged as `detected`, so re-running a step on an existing machine fills in the log.

## Steps

| Step | Installs | Extras |
|---|---|---|
| `bootstrap` | | SSH key → GitHub, git identity |
| **CLI** | | |
| `minimal` | `minimal.list` | GitHub CLI repo, timezone, `en_US.UTF-8` locale, sshd enabled (always-on, not socket-activated) |
| `network` | `network.list`, `wifi.list` | Tailscale repo, vpn-slice, VPN password in pass; `wifi.list` (nm-applet) only when a wireless interface exists |
| `files` | `files.list` | |
| `dev` | `dev.list` | NodeSource repo, Docker (`bin/docker_install.sh`), Claude Code + skills, Gemini CLI, Antigravity, Miniconda + `tools` env (`python.libs`), radian, fabric, Singularity |
| `tools` | `tools.list` | tldr (tealdeer) + pages cache, Bitwarden CLI (`bw`, native binary → `~/.local/bin`) |
| **Desktop** | | |
| `desktop` | `desktop.list` | Hyprland PPA (incl. hyprsunset night light), Nerd Fonts, Zafiro + Qogir themes |
| `display` | `display.list` | |
| `audio` | `audio.list` | |
| `bluetooth` | `bluetooth.list` | skipped without a bluetooth adapter; `/etc/bluetooth` mode 555 |
| `media` | `media.list`, `media.flatpak` | yt-dlp via pipx with `curl_cffi` (`--impersonate`) |
| `web` | `web.list` | Brave + Mozilla repos, browser logins, Tor Browser |
| `system` | `system.list` | upower enabled at boot |
| `apps` | `apps.list`, `apps.flatpak` | FUTO Notes repo, AppIndicator GNOME extension (Proton VPN tray icon), Thunar as default folder handler |
| `firewall` | ufw | resets ufw to deny-all-incoming + allowlist: ssh on tailscale0 + private LANs, tailscale 41641/udp, mDNS, Syncthing 22000 + 21027/udp (not on work PC), Grayjay sync 12315/tcp + cast (ephemeral tcp ports, private LANs only); silent IGMP drop |
| `greeter` | — | skipped on the work profile; otherwise asks first (default **no**): replaces the display manager (gdm3) with greetd + tuigreet on tty1; quiet boot/kernel console so nothing prints over the login |
| **Device** | | |
| `carbon` | `carbon.list` | ThinkPad X1 Carbon 5th gen only (auto-detected from DMI): coretemp/RAPL early load for thermald, `initcall_blacklist=intel_uncore_init` (resource sanity warning), optional SD reader blacklist, optional ModemManager off (no SIM) |
| **After packages** | | |
| `dotfiles` | | symlinks from `config/dotfiles.state`, ~/utils repo, /etc/hosts (`dotfiles.sh --links`: symlinks only) |
| `functions` | `functions.list` | yt-dlp via pipx with `curl_cffi`, `functions/*` executable and on PATH (`~/.locales`), `~/.history/query` for `query` (prompt: `patterns/query.md`), `~/tunel` (offers `Host mentat` + key for `tunelcp`, not on mentat); warns about each function's missing commands |
| `second-brain` | | Obsidian, `second-brain/setup.sh` |
| `data` | — | skipped on the work profile and on mentat (the hub); where Drive lives (see above), `~/<dir>` links, then `syncthing` (except with the sshfs layout) |
| `syncthing` | — | Syncthing in Docker (`config/syncthing/compose.yml`, per-machine values in `~/.local/state/ledot/syncthing.env`; ports opened by `firewall`), pairs `Drive` with mentat over ssh; removes the apt package/user service |
| `r` | `r-build.list`, `r.libs` | R packages; runs last and asks first (default **no**) — slow to build |
| **Optional** (not in the full run: `install.sh <step>`) | | |
| `elegoo` | `elegoo.list` | ElegooSlicer release AppImage → `~/.local/bin/elegoo-slicer` + menu entry; `--source` builds it with Ubuntu 26.04 fixes ([docs/printers/elegoo-slicer.md](../docs/printers/elegoo-slicer.md)) |

Shared helpers (colors, `confirm`, `install_list`, `install_flatpaks`, `confirm_no`, `pipx_install`, `track_install`, `track_detected`, profiles, mentat/hub settings, `ensure_hub_ssh`) live in `lib/common.sh`; disk planning for `data` in `lib/partition.sh`.
