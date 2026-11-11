# common.sh — shared helpers for setup/*.sh (source it, don't run it)

DOTFILES="${HOME}/ledot"
PKGS="${DOTFILES}/pkgs"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
info()   { echo -e "${GREEN}[✓]${RESET} $*"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $*"; }
die()    { echo -e "${RED}[✗]${RESET} $*" >&2; exit 1; }
header() { echo -e "\n${BLUE}${BOLD}━━━ $* ━━━${RESET}\n"; }
note()   { echo -e "  ${CYAN}ℹ${RESET}  $*"; }

confirm() {
    local prompt="${1:-Continue?}"
    local ans
    read -rp "$(echo -e "${YELLOW}[?]${RESET} ${prompt} [Y/n] ")" ans
    [[ "${ans,,}" != "n" ]]
}

# ── Machine profile ──────────────────────────────────────────────────────────
# personal — daily-driver PC (carbon): everything
# server   — headless host (mentat, fremen, …): lean, no desktop/second-brain
# work     — shared work PC (lgcm): asks before every step; no Syncthing, /data or personal state
LEDOT_STATE="${XDG_STATE_HOME:-${HOME}/.local/state}/ledot"
PROFILE_FILE="${LEDOT_STATE}/profile"
PROFILES=(personal server work)

# Known machines; anything else is asked once (then remembered in $PROFILE_FILE)
declare -A KNOWN_PROFILES=([carbon]=personal [mentat]=server [fremen]=server [sardaukar]=server [lgcm]=work)

valid_profile() { [[ " ${PROFILES[*]} " == *" $1 "* ]]; }

save_profile() {
    valid_profile "$1" || die "Unknown profile: $1 (${PROFILES[*]})"
    mkdir -p "$LEDOT_STATE"
    echo "$1" > "$PROFILE_FILE"
}

# machine_profile — print this machine's profile: $LEDOT_PROFILE, saved, known hostname, or ask (prompts go to stderr)
machine_profile() {
    if [ -n "${LEDOT_PROFILE:-}" ]; then echo "$LEDOT_PROFILE"; return; fi
    if [ -s "$PROFILE_FILE" ]; then cat "$PROFILE_FILE"; return; fi
    local p="${KNOWN_PROFILES[$(hostname)]:-}"
    if [ -z "$p" ]; then
        {
            echo -e "${YELLOW}[?]${RESET} New machine '$(hostname)' — which profile?"
            echo "     1) personal  daily-driver PC: everything (desktop, Syncthing /data/drive, second-brain)"
            echo "     2) server    headless host: lean CLI + Syncthing /data/drive"
            echo "     3) work      shared work PC: asks before every step, nothing personal"
        } >&2
        local ans
        read -rp "     Profile [1-3]: " ans
        case "$ans" in 1|personal) p=personal ;; 2|server) p=server ;; 3|work) p=work ;; *) die "No profile chosen" ;; esac
    fi
    save_profile "$p"
    echo "$p"
}

# is_work — the work PC: no greeter swap, no Syncthing or /data, nothing personal
is_work() { [ "$(machine_profile)" = "work" ]; }

# ── Hub (mentat) ─────────────────────────────────────────────────────────────
# mentat runs the Syncthing hub (~/stacks/syncthing, lscr image) every machine's /data/drive syncs with
HUB_HOST="mentat"                  # its hostname and ~/.ssh/config alias
HUB_USER="fm"
HUB_LAN_IP="192.168.15.200"        # used when tailscale's MagicDNS can't resolve $HUB_HOST
HUB_DRIVE="/data/drive"
HUB_FOLDER_ID="gfkqq-hqhzy"        # Syncthing "Drive" folder (path $HUB_DRIVE on every machine)
HUB_ST_CLI="docker exec -u abc syncthing syncthing cli --home /config"
SSH_KEY="${HOME}/.ssh/id_ed25519"

is_hub() { [ "$(hostname)" = "$HUB_HOST" ]; }

has_hub_ssh_entry() { grep -qiE "^\s*Host\s+(.*\s)?${HUB_HOST}(\s|$)" "${HOME}/.ssh/config" 2>/dev/null; }

hub_ssh() { ssh -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new "$HUB_HOST" "$@"; }

# ensure_hub_ssh — make `ssh mentat` work without a password: Host entry, key, key on mentat (asks each); 1 if not
ensure_hub_ssh() {
    is_hub && return 0
    if ! has_hub_ssh_entry; then
        local addr="$HUB_HOST"
        getent hosts "$HUB_HOST" &>/dev/null || addr="$HUB_LAN_IP"
        confirm "Add 'Host ${HUB_HOST}' (→ ${HUB_USER}@${addr}) to ~/.ssh/config?" || return 1
        mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
        printf '\nHost %s\n    HostName %s\n    User %s\n    IdentityFile %s\n    IdentitiesOnly yes\n' \
            "$HUB_HOST" "$addr" "$HUB_USER" "${SSH_KEY/#$HOME/\~}" >> "${HOME}/.ssh/config"
        chmod 600 "${HOME}/.ssh/config"
        info "~/.ssh/config: Host ${HUB_HOST} → ${addr}"
    fi
    if [ ! -f "$SSH_KEY" ]; then
        confirm "No SSH key — generate ${SSH_KEY/#$HOME/\~}?" || return 1
        ssh-keygen -q -t ed25519 -C "${USER}@$(hostname)" -f "$SSH_KEY" -N ""
    fi
    hub_ssh true 2>/dev/null && { info "ssh ${HUB_HOST} OK"; return 0; }
    warn "ssh ${HUB_HOST} needs a password (or ${HUB_HOST} is unreachable)"
    confirm "Copy your key to ${HUB_HOST} (asks ${HUB_USER}'s password there)?" || return 1
    ssh-copy-id -i "${SSH_KEY}.pub" -o StrictHostKeyChecking=accept-new "$HUB_HOST" || return 1
    hub_ssh true && info "ssh ${HUB_HOST} OK"
}

# has_wifi — any wireless network interface present
has_wifi() { compgen -G "/sys/class/net/*/wireless" > /dev/null; }

# confirm_no — like confirm, but Enter means no
confirm_no() {
    local prompt="${1:-Continue?}"
    local ans
    read -rp "$(echo -e "${YELLOW}[?]${RESET} ${prompt} [y/N] ")" ans
    [[ "${ans,,}" == "y" ]]
}

# apt_update — apt-get update with retries; a flaky repo (mirror mid-sync) warns instead of aborting
apt_update() {
    local i
    for i in 1 2 3; do
        sudo apt-get update -qq && return 0
        [ "$i" -lt 3 ] && { warn "apt-get update failed (try $i/3), retrying in 10s..."; sleep 10; }
    done
    warn "apt-get update still failing — continuing with cached package lists"
}

# apt-install every package in pkgs/<name>.list (blank and '#' lines skipped)
install_list() {
    local list="${PKGS}/$1.list"
    local pkgs=()
    [ -f "$list" ] || die "$list not found"
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        pkgs+=("$line")
    done < "$list"
    [ ${#pkgs[@]} -eq 0 ] && return
    info "Installing $1.list (${#pkgs[@]} packages)..."
    sudo apt-get install -y "${pkgs[@]}"
    info "$1.list done"
}

# pipx_install <tool> — install a pipx tool unless already on PATH (asks first)
pipx_install() {
    local tool="$1"
    if command -v "$tool" &>/dev/null; then
        info "$tool already installed — skipping"
        track_detected "$tool" "$(pipx_version "$tool")"
        return 0
    fi
    confirm "Install $tool (pipx)?" || return 0
    command -v pipx &>/dev/null || sudo apt-get install -y pipx
    pipx install "$tool"
    track_install "$tool" pipx "$(pipx_version "$tool")"
    info "$tool installed"
}

pipx_version() {
    pipx list --short 2>/dev/null | awk -v t="$1" '$1 == t { print $2 }'
}

# install_ytdlp — yt-dlp via pipx with curl_cffi (browser impersonation, --impersonate);
# Ubuntu has no python3-curl-cffi, so the apt yt-dlp can't use it. Idempotent.
install_ytdlp() {
    command -v pipx &>/dev/null || sudo apt-get install -y pipx
    if pipx list --short 2>/dev/null | awk '$1 == "yt-dlp" { f=1 } END { exit !f }'; then
        pipx inject -q yt-dlp curl_cffi
        info "yt-dlp (pipx) present — curl_cffi ensured"
    else
        pipx install "yt-dlp[default,curl-cffi]"
        track_install yt-dlp pipx "$(pipx_version yt-dlp)"
        info "yt-dlp installed (pipx, with curl_cffi)"
    fi
    dpkg -s yt-dlp &>/dev/null \
        && note "apt yt-dlp also installed (shadowed by ~/.local/bin): sudo apt remove yt-dlp"
    return 0
}

# flatpak-install every app ID in pkgs/<name>.flatpak from Flathub (blank and '#' lines skipped)
install_flatpaks() {
    local list="${PKGS}/$1.flatpak"
    local apps=()
    [ -f "$list" ] || die "$list not found"
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        apps+=("$line")
    done < "$list"
    [ ${#apps[@]} -eq 0 ] && return
    command -v flatpak &>/dev/null || sudo apt-get install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    info "Installing $1.flatpak (${#apps[@]} apps)..."
    sudo flatpak install -y --noninteractive flathub "${apps[@]}"
    info "$1.flatpak done"
}

# ── Install state ────────────────────────────────────────────────────────────
# Installs that apt/flatpak don't track (tarballs, curl installers, npm, pipx, conda, git clones)
# are logged in $XDG_STATE_HOME/ledot/installs.tsv: name, source, version, date (one line per name)
INSTALL_STATE="${XDG_STATE_HOME:-${HOME}/.local/state}/ledot/installs.tsv"

# track_install <name> <source> [version] — add or replace <name>'s line
track_install() {
    local tmp
    mkdir -p "$(dirname "$INSTALL_STATE")"
    tmp=$(mktemp)
    [ -f "$INSTALL_STATE" ] && awk -F'\t' -v n="$1" '$1 != n' "$INSTALL_STATE" > "$tmp"
    printf '%s\t%s\t%s\t%s\n' "$1" "$2" "${3:--}" "$(date +%F)" >> "$tmp"
    mv "$tmp" "$INSTALL_STATE"
}

# track_detected <name> [version] — log something found already installed, unless it's already logged
track_detected() {
    grep -q "^$1	" "$INSTALL_STATE" 2>/dev/null || track_install "$1" detected "${2:-}"
}
