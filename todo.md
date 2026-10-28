# TODO
#todo

## Main

- [x] automate 00.init
- [x] fix redundancy of 02.setup vs. 03.setup-dotfiles
- [x] move from dmenu to rofi
- [x] add to pkgs/installation:
    - [x] brave-bin
    - [x] pass
    - [x] openconnect
    - [x] gpg
    - [x] arandr
    - [x] w3m
    - [x] ranger

## Others
### Customizations
- [x] add wifi logo to polybar
- [x] only show wifi type of connection in polybar (rm enp0s31f6 from polybar)
- [x] add to polybar: battery charge (battery status if device has batery)
- [x] add to polybar: session menu (exit, restart, etc)
- [x] add split to configs based on hostname (activate configs based on which pc i`m at)
- [x] add to vpn: vpn split
- [x] add to vpn: vpn check
- [x] add to i3: send/get back window to scratchpad
- [x] add to i3: quick terminal (mod+shift+return)
- [x] setup correct timezone

### Automations
automate setup for:
- [x] pass
- [x] gpg
- [ ] copy config/ssh_config to ~/.ssh/config
- [ ] send ssh id to servers

### Pending installs
i3wm / ricing:
- [x] sxhkd (hotkey daemon)            → pkgs-gui.list
- [x] nitrogen (alternative wallpaper GUI) → pkgs-gui.list

Privacy / Networking:
- [x] tailscale                         → pkgs-cli.list + 02.setup-distro repo
- [x] tor                               → pkgs-cli.list
- [x] brotab (browser tab control from CLI) → 04.manual-setup (pip)

Containers / HPC:
- [x] docker + docker compose           → pkgs-cli.list + 02.setup-distro repo
- [x] singularity                       → apt install singularity-container

Data Science:
- [x] miniconda                         → 04.manual-setup (installer)
- [x] create conda env called tools & install libs from conda.libs
- [x] R + radian                        → r-base in pkgs-cli.list, radian in 04.manual-setup
- [x] install r packges from R.libs

AI / Automation:
- [x] fabric                            → 04.manual-setup (pipx)

CLI Utilities:
- [x] batcat (bat)                      → pkgs-cli.list
- [x] ncdu                              → pkgs-cli.list
- [x] net-tools                         → pkgs-cli.list
- [x] rmlint                            → pkgs-cli.list
- [x] odt2txt                           → pkgs-cli.list
- [x] ffmpegthumbnailer                 → pkgs-cli.list
- [x] unrar, atool                      → pkgs-cli.list
- [x] exiftool (libimage-exiftool-perl) → pkgs-cli.list
- [x] highlight                         → pkgs-cli.list
- [x] mediainfo                         → pkgs-cli.list
- [x] yt-dlp                            → pkgs-cli.list
- [x] transmission-cli                  → pkgs-cli.list

GUI Utilities:
- [x] mpv                               → pkgs-gui.list
- [x] transmission                      → pkgs-gui.list (transmission-gtk)
- [x] Tor Browser                       → 04.manual-setup (torbrowser-launcher)

### Refactor
- [ ] refactor configs from archcraft pattern (all in i3/) to each on its on folder in .dotfiles
- [ ] add keymap to auto-detect available displays (turn on laptop display when hdmi is no longer connected)
- [ ] automate git clone for: tools, bench, etc
- [ ] achar solução melhor e + simples de se lidar com git-crypt no tools (.env)

## Fix
- [x] add earliest point in distro setup where i can enter gui mode (logout and login again). script should instruct user
- [ ] gh refresh not working: it expects user input, and the autmated script skip/suppress it
- [x] vim keymap not working: space+y+y copy selected text in vim to clipboard 
- [ ] add coded/fixed name/email to gpg, github, git, etc setup
- [x] add in brave manual config: open sync tab (brave://settings/braveSync/setup)
- [x] add in brave manual config: open bitwarden extension page (https://chromewebstore.google.com/detail/bitwarden-password-manage/nngceckbapebfimnlniiiahkandclblb?browser=brave) 
- [x] issue during miniconda3 install: it automatically generates the following code into .bashrc, creating issue:
```bash
  conda() {
      unset -f conda
      if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
  # . "$HOME/miniconda3/etc/profile.d/conda.sh"  # commented out by conda initialize
E     fi # E: syntax error near unexpected token `fi'
      conda "$@"
  }
```

issue:

```bash
bash: /home/fm/.bashrc: line 101: syntax error near unexpected token `fi'
bash: /home/fm/.bashrc: line 101: `    fi'
```
- [x] fix r pkgs installation:
```bash
* DONE (modelr)
ERROR: dependencies ‘googledrive’, ‘googlesheets4’, ‘httr’, ‘ragg’, ‘reprex’, ‘rvest’ are not available for package ‘tidyverse’
* removing ‘/home/fm/R/x86_64-pc-linux-gnu-library/4.3/tidyverse’

The downloaded source packages are in
        ‘/tmp/RtmpRcuTM5/downloaded_packages’
There were 17 warnings (use warnings() to see them)
[✓] R packages installed
```

- [x] immplement: 06.setup_data
      1. mount /dev/nvme0n1p3 to /data
      2. mkdir /data/vault
      3. link:
          3.1 /data/vault/Documents → ~/Documents
          3.2 ~/code → /data/vault/code
          3.3 ~/homelab -> /data/vault/homelab
          3.4 /data/vault/Music → ~/Music
          3.5 /data/vault/Pictures → ~/Pictures
          3.6 /data/vault/Videos → ~/Videos
          3.7 ~/work → /data/vault/work
          3.8 ~/Vaults → /data/vault/Vaults
            
