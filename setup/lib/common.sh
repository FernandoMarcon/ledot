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
