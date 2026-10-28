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
        return 0
    fi
    confirm "Install $tool (pipx)?" || return 0
    command -v pipx &>/dev/null || sudo apt-get install -y pipx
    pipx install "$tool"
    info "$tool installed"
}
