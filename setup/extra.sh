#!/bin/bash
# extra.sh → pkgs/extra.catalog: optional tools (redundant with a default, or for specific situations), picked in a menu
# Menu: ↑↓/jk move, space ticks/unticks, enter applies — ticked tools get installed, unticked installed ones removed
# Usage: bash ~/ledot/setup/extra.sh           menu (falls back to --ask without a terminal)
#        bash ~/ledot/setup/extra.sh --ask     ask y/N for each tool not installed yet (no removals)
#        bash ~/ledot/setup/extra.sh --list    catalog with install status

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

CATALOG="${PKGS}/extra.catalog"
[ -f "$CATALOG" ] || die "$CATALOG not found"

# ── Custom installers (kind=custom: has_/install_/remove_<target>) ──────────
deb_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'; }

has_brave() { deb_installed brave-browser; }
install_brave() {
    # Brave's installer adds its apt repo and installs brave-browser; download first so a failed fetch is reported
    local installer
    installer="$(mktemp)"
    curl -fsS https://dl.brave.com/install.sh -o "$installer" && sh "$installer"
    local rc=$?
    rm -f "$installer"
    return $rc
}
remove_brave() { sudo apt-get remove -y brave-browser; }

has_obsidian() { deb_installed obsidian; }
install_obsidian() {
    local version
    version=$(curl -fsSL https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | jq -r .tag_name)
    version="${version#v}"
    [ -n "$version" ] && [ "$version" != null ] || { warn "Couldn't read Obsidian's latest release"; return 1; }
    local tmp
    tmp=$(mktemp -d)
    chmod 755 "$tmp"   # let apt's sandbox user (_apt) read the .deb
    curl -fsSL "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/obsidian_${version}_amd64.deb" \
        -o "$tmp/obsidian.deb" \
        && sudo apt-get install -y "$tmp/obsidian.deb" \
        && track_install obsidian "github:obsidianmd/obsidian-releases (.deb)" "$version"
    local rc=$?
    rm -rf "$tmp"
    return $rc
}
remove_obsidian() { sudo apt-get remove -y obsidian && track_forget obsidian; }

has_antigravity() { deb_installed antigravity; }
install_antigravity() {
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg \
        | sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg || return 1
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" \
        | sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null
    apt_update
    sudo apt-get install -y antigravity
}
remove_antigravity() { sudo apt-get remove -y antigravity; }

# ── Catalog ──────────────────────────────────────────────────────────────────
# Parallel arrays, one index per tool: group, name, kind, target, description; HAVE = installed now, WANT = ticked
G=(); N=(); K=(); T=(); D=(); HAVE=(); WANT=()
profile="$(machine_profile)"
# Desktop apps only show where there's a desktop (Hyprland or any running graphical session)
has_desktop=0
if deb_installed hyprland || [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then has_desktop=1; fi
while IFS='|' read -r g n k t gui d; do
    [[ -z "$g" || "$g" == \#* ]] && continue
    [ "$gui" = 1 ] && [ "$has_desktop" = 0 ] && continue
    G+=("$g"); N+=("$n"); K+=("$k"); T+=("$t"); D+=("$d")
done < "$CATALOG"

# is_installed <i> — for apt, the first package is the tool (the rest are helpers installed along with it)
is_installed() {
    local i=$1
    case "${K[i]}" in
        apt)     deb_installed "${T[i]%% *}" ;;
        flatpak) command -v flatpak &>/dev/null && flatpak info "${T[i]}" &>/dev/null ;;
        custom)  "has_${T[i]}" ;;
        *)       return 1 ;;
    esac
}

refresh_status() {
    local i
    for i in "${!N[@]}"; do
        if is_installed "$i"; then HAVE[i]=1; else HAVE[i]=0; fi
        WANT[i]=${HAVE[i]}
    done
}

ensure_flathub() {
    command -v flatpak &>/dev/null || sudo apt-get install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

do_install() {
    local i=$1
    case "${K[i]}" in
        # shellcheck disable=SC2086  # target is a space-separated package list
        apt)     sudo apt-get install -y ${T[i]} ;;
        flatpak) ensure_flathub && sudo flatpak install -y --noninteractive flathub "${T[i]}" ;;
        custom)  "install_${T[i]}" ;;
    esac
}

do_remove() {
    local i=$1
    case "${K[i]}" in
        apt)     sudo apt-get remove -y "${T[i]%% *}" ;;
        flatpak) sudo flatpak uninstall -y --noninteractive "${T[i]}" ;;
        custom)  "remove_${T[i]}" ;;
    esac
}

# apply <ask> — install ticked tools that are missing, remove unticked ones that are installed
apply() {
    local ask=$1 i add=() del=() names
    for i in "${!N[@]}"; do
        if [ "${WANT[i]}" = 1 ] && [ "${HAVE[i]}" = 0 ]; then add+=("$i")
        elif [ "${WANT[i]}" = 0 ] && [ "${HAVE[i]}" = 1 ]; then del+=("$i"); fi
    done
    if [ ${#add[@]} -eq 0 ] && [ ${#del[@]} -eq 0 ]; then
        info "Nothing to change"
        return 0
    fi
    if [ ${#add[@]} -gt 0 ]; then names=""; for i in "${add[@]}"; do names+=" ${N[i]}"; done; echo -e "  ${GREEN}install:${RESET}${names}"; fi
    if [ ${#del[@]} -gt 0 ]; then names=""; for i in "${del[@]}"; do names+=" ${N[i]}"; done; echo -e "  ${RED}remove:${RESET} ${names}"; fi
    if [ "$ask" = 1 ] && ! confirm "Apply these changes?"; then
        info "Nothing changed"
        return 0
    fi

    for i in "${add[@]}"; do
        [ "${K[i]}" = apt ] && { apt_update; break; }
    done
    local failed=0
    for i in "${add[@]}"; do
        header "extra: install ${N[i]}"
        if do_install "$i" && is_installed "$i"; then info "${N[i]} installed"
        else warn "${N[i]} failed to install"; failed=1; fi
    done
    for i in "${del[@]}"; do
        header "extra: remove ${N[i]}"
        if do_remove "$i" && ! is_installed "$i"; then info "${N[i]} removed"
        else warn "${N[i]} failed to remove"; failed=1; fi
    done
    [ ${#del[@]} -gt 0 ] && note "Leftover dependencies: sudo apt autoremove"
    return $failed
}

# ── Menu (TUI) ───────────────────────────────────────────────────────────────
E=$'\e'
M_RESET="${E}[0m"; M_BOLD="${E}[1m"; M_DIM="${E}[2m"; M_REV="${E}[7m"
M_GREEN="${E}[32m"; M_YELLOW="${E}[33m"; M_RED="${E}[31m"; M_BLUE="${E}[34m"; M_CYAN="${E}[36m"

ROWS_=()    # menu lines: "h:<group>" (header) or "i:<index>" (tool)
cur=0; top=0

build_rows() {
    local i prev=""
    for i in "${!N[@]}"; do
        [ "${G[i]}" != "$prev" ] && { ROWS_+=("h:${G[i]}"); prev="${G[i]}"; }
        ROWS_+=("i:$i")
    done
    cur=1   # first tool (row 0 is its group header)
}

# move <±n> — next tool row in that direction, skipping headers; stays put at the ends
move() {
    local d=$1 j=$cur steps=${2:-1}
    while [ "$steps" -gt 0 ]; do
        j=$((j + d))
        if [ "$j" -lt 0 ] || [ "$j" -ge ${#ROWS_[@]} ]; then return 0; fi
        if [[ ${ROWS_[j]} == i:* ]]; then cur=$j; steps=$((steps - 1)); fi
    done
}

hline() { local s; printf -v s '%*s' "$1" ''; printf '%s' "${s// /─}"; }

draw() {
    local rows cols lw=30 pw px list_h side=1 r idx row line i mark name flag status buf
    rows=$(tput lines); cols=$(tput cols)
    pw=$((cols - lw - 4)); px=$((lw + 3))
    [ "$pw" -gt 60 ] && pw=60
    list_h=$((rows - 4))
    if [ "$pw" -lt 26 ]; then side=0; pw=$((cols - 2)); px=2; list_h=$((rows - 12)); fi
    [ "$list_h" -lt 3 ] && list_h=3

    # keep the cursor (and its group header) on screen
    if [ "$cur" -le "$top" ]; then top=$((cur - 1)); [ "$top" -lt 0 ] && top=0; fi
    [ "$cur" -ge $((top + list_h)) ] && top=$((cur - list_h + 1))

    buf="${E}[H${E}[2J${E}[1;2H${M_BOLD}ledot extra${M_RESET}${M_DIM} — optional tools (${profile})${M_RESET}"
    for ((r = 0; r < list_h; r++)); do
        idx=$((top + r))
        [ "$idx" -ge ${#ROWS_[@]} ] && break
        row=$((r + 3)); line=${ROWS_[idx]}
        if [[ $line == h:* ]]; then
            buf+="${E}[${row};2H${M_BLUE}${M_BOLD}${line#h:}${M_RESET}"
            continue
        fi
        i=${line#i:}
        if [ "${WANT[i]}" = 1 ]; then mark="[x]"; else mark="[ ]"; fi
        name="${N[i]}"
        if [ "${HAVE[i]}" = 1 ]; then name="${M_GREEN}${name}"; fi
        flag=""
        if [ "${WANT[i]}" != "${HAVE[i]}" ]; then
            if [ "${WANT[i]}" = 1 ]; then flag=" ${M_YELLOW}+install"; else flag=" ${M_RED}-remove"; fi
        fi
        if [ "$idx" -eq "$cur" ]; then
            buf+="${E}[${row};2H${M_REV} ${mark} ${name}${M_RESET}${M_REV}${flag} ${M_RESET}"
        else
            buf+="${E}[${row};2H ${mark} ${name}${M_RESET}${flag}${M_RESET}"
        fi
    done

    # side (or bottom) panel: the tool under the cursor
    i=${ROWS_[cur]#i:}
    if [ "${WANT[i]}" != "${HAVE[i]}" ]; then
        if [ "${WANT[i]}" = 1 ]; then status="${M_YELLOW}will be installed"; else status="${M_RED}will be removed"; fi
    elif [ "${HAVE[i]}" = 1 ]; then status="${M_GREEN}installed"
    else status="${M_DIM}not installed"; fi
    local -a wrapped
    mapfile -t wrapped < <(fold -s -w $((pw - 4)) <<< "${D[i]}")
    local py=3 inner=$((pw - 2))
    [ "$side" = 0 ] && py=$((list_h + 4))
    buf+="${E}[${py};${px}H${M_DIM}┌$(hline "$inner")┐${M_RESET}"
    local -a body=("${M_BOLD}${N[i]}${M_RESET}" "${M_DIM}${G[i]} · ${K[i]}: ${T[i]}${M_RESET}" "${status}${M_RESET}" "" "${wrapped[@]}")
    for line in "${body[@]}"; do
        py=$((py + 1))
        buf+="${E}[${py};${px}H${M_DIM}│${M_RESET} ${line}${E}[${py};$((px + pw - 1))H${M_DIM}│${M_RESET}"
    done
    py=$((py + 1))
    buf+="${E}[${py};${px}H${M_DIM}└$(hline "$inner")┘${M_RESET}"

    buf+="${E}[${rows};2H${M_CYAN}↑↓${M_RESET} move  ${M_CYAN}space${M_RESET} tick  ${M_CYAN}enter${M_RESET} apply  ${M_CYAN}q${M_RESET} quit"
    [ "$cols" -ge 64 ] && buf+="   ${M_GREEN}green${M_RESET} = installed"
    printf '%s' "$buf"
}

menu_restore() { printf '%s' "${E}[?25h"; tput rmcup 2>/dev/null || true; stty echo 2>/dev/null || true; }

# menu — returns 0 to apply, 1 if quit
menu() {
    local key rest
    build_rows
    tput smcup 2>/dev/null || true
    printf '%s' "${E}[?25l"
    stty -echo
    trap 'menu_restore' EXIT INT TERM
    trap 'draw' WINCH
    while :; do
        draw
        IFS= read -rsn1 key || true
        case "$key" in
            "$E")
                rest=""
                IFS= read -rsn2 -t 0.05 rest || true
                case "$rest" in
                    '[A') move -1 ;;
                    '[B') move 1 ;;
                    '[5') IFS= read -rsn1 -t 0.05 rest || true; move -1 5 ;;   # PgUp
                    '[6') IFS= read -rsn1 -t 0.05 rest || true; move 1 5 ;;    # PgDn
                    '') menu_restore; trap - EXIT INT TERM WINCH; return 1 ;;  # Esc
                esac ;;
            k) move -1 ;;
            j) move 1 ;;
            ' ') i=${ROWS_[cur]#i:}; WANT[i]=$((1 - WANT[i])) ;;
            '') menu_restore; trap - EXIT INT TERM WINCH; return 0 ;;          # Enter
            q|Q) menu_restore; trap - EXIT INT TERM WINCH; return 1 ;;
        esac
    done
}

# ── Main ─────────────────────────────────────────────────────────────────────
refresh_status

case "${1:-}" in
    --list)
        prev=""
        for i in "${!N[@]}"; do
            [ "${G[i]}" != "$prev" ] && { echo -e "${BLUE}${BOLD}${G[i]}${RESET}"; prev="${G[i]}"; }
            if [ "${HAVE[i]}" = 1 ]; then s="${GREEN}installed${RESET}"; else s="-"; fi
            printf "  %-14s %b\n" "${N[i]}" "$s"
        done
        exit 0
        ;;
    --ask) mode=ask ;;
    "")
        if [ -t 0 ] && [ -t 1 ] && [ "${TERM:-dumb}" != dumb ] && command -v tput &>/dev/null; then mode=menu; else mode=ask; fi
        ;;
    *) die "Unknown option: $1 (--ask, --list)" ;;
esac

if [ "$mode" = menu ]; then
    if ! menu; then
        info "Quit — nothing changed"
        exit 0
    fi
    apply 1
else
    # One y/N per tool not installed yet (Enter = no); installed ones are kept
    for i in "${!N[@]}"; do
        if [ "${HAVE[i]}" = 1 ]; then
            info "${N[i]} already installed"
            continue
        fi
        note "${D[i]}"
        if confirm_no "Install ${N[i]} (${G[i]})?"; then WANT[i]=1; fi
    done
    apply 0
fi
