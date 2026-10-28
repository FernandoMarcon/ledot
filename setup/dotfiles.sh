#!/bin/bash
# dotfiles.sh — manage dotfile symlinks via state file
# Run after: the package scripts (packages must exist for post-activate hooks)
# Usage:
#   dotfiles.sh              — apply current state from dotfiles.state, then ~/tools and /etc/hosts
#   dotfiles.sh --links      — apply state links only (no ~/tools, /etc/hosts or plugin installs)
#   dotfiles.sh [item ...]   — activate specific items (use 'tools' to set up ~/tools)

set -euo pipefail

DOTFILES="${HOME}/ledot"
CONFIG="${HOME}/.config"
STATE_FILE="${DOTFILES}/config/dotfiles.state"

declare -A ITEM_SRC ITEM_DST

ITEM_SRC[aliases]="${DOTFILES}/config/aliases";       ITEM_DST[aliases]="${HOME}/.aliases"
ITEM_SRC[alacritty]="${DOTFILES}/config/alacritty";   ITEM_DST[alacritty]="${CONFIG}/alacritty"
ITEM_SRC[bashrc]="${DOTFILES}/config/bashrc";         ITEM_DST[bashrc]="${HOME}/.bashrc"
ITEM_SRC[cava]="${DOTFILES}/config/cava";             ITEM_DST[cava]="${CONFIG}/cava"
ITEM_SRC[hypr]="${DOTFILES}/config/hypr";             ITEM_DST[hypr]="${CONFIG}/hypr"
ITEM_SRC[locales]="${DOTFILES}/config/locales";       ITEM_DST[locales]="${HOME}/.locales"
ITEM_SRC[profile]="${DOTFILES}/config/profile";       ITEM_DST[profile]="${HOME}/.profile"
ITEM_SRC[quickshell]="${DOTFILES}/config/quickshell"; ITEM_DST[quickshell]="${CONFIG}/quickshell"
ITEM_SRC[ranger]="${DOTFILES}/config/ranger";         ITEM_DST[ranger]="${CONFIG}/ranger"
ITEM_SRC[rofi]="${DOTFILES}/config/rofi";             ITEM_DST[rofi]="${CONFIG}/rofi"
ITEM_SRC[tmux]="${DOTFILES}/config/tmux";             ITEM_DST[tmux]="${CONFIG}/tmux"
ITEM_SRC[vim]="${DOTFILES}/config/vim";               ITEM_DST[vim]="${CONFIG}/vim"
ITEM_SRC[waybar]="${DOTFILES}/config/waybar";         ITEM_DST[waybar]="${CONFIG}/waybar"

ALL_ITEMS=(aliases alacritty bashrc cava hypr locales profile quickshell ranger rofi tmux vim waybar)

# --links: symlinks only, skip post-activate hooks, ~/tools and /etc/hosts
LINKS_ONLY=0

init_state_file() {
    if [ ! -f "$STATE_FILE" ]; then
        for item in "${ALL_ITEMS[@]}"; do
            printf "%-12s no\n" "$item" >> "$STATE_FILE"
        done
        echo "Created state file: $STATE_FILE"
    else
        for item in "${ALL_ITEMS[@]}"; do
            if ! grep -q "^${item} " "$STATE_FILE"; then
                printf "%-12s no\n" "$item" >> "$STATE_FILE"
            fi
        done
    fi
}

get_state() {
    grep "^${1} " "$STATE_FILE" 2>/dev/null | awk '{print $2}'
}

set_state() {
    local item="$1" state="$2"
    if grep -q "^${item} " "$STATE_FILE"; then
        sed -i "s/^${item} .*$/$(printf "%-12s" "$item") ${state}/" "$STATE_FILE"
    else
        printf "%-12s %s\n" "$item" "$state" >> "$STATE_FILE"
    fi
}

is_dotfiles_link() {
    local dst="$1" src="$2"
    [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]
}

activate() {
    local item="$1"
    local src="${ITEM_SRC[$item]}"
    local dst="${ITEM_DST[$item]}"

    if [ ! -e "$src" ]; then
        echo "  [!] $item: source not found ($src), skipping"
        return 1
    fi

    if is_dotfiles_link "$dst" "$src"; then
        echo "  [=] $item: already active"
    else
        if [ -L "$dst" ]; then
            # Foreign or dangling symlink: nothing to keep
            echo "  [~] $item: replacing symlink → $(readlink "$dst")"
            rm "$dst"
        elif [ -e "$dst" ]; then
            # Real file/dir: back it up (timestamped if a _bkp already exists)
            local bkp="${dst}_bkp"
            [ -e "$bkp" ] && bkp="${dst}-$(date +%s)-bkp"
            echo "  [~] $item: backing up $(basename "$dst") → $(basename "$bkp")"
            mv "$dst" "$bkp"
        fi

        mkdir -p "$(dirname "$dst")"
        ln -sf "$src" "$dst"
        echo "  [+] $item: activated"
    fi

    set_state "$item" "yes"

    [ "$LINKS_ONLY" -eq 1 ] && return 0
    if declare -f "post_activate_${item}" > /dev/null 2>&1; then
        "post_activate_${item}"
    fi
}

post_activate_bashrc() {
    if ! command -v starship &>/dev/null; then
        echo "  [>] bashrc: installing starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
        echo "  [>] bashrc: starship installed"
    fi
}

post_activate_tmux() {
    local tpm="${CONFIG}/tmux/plugins/tpm"
    if [ ! -d "$tpm" ]; then
        echo "  [>] tmux: installing TPM..."
        git clone --quiet https://github.com/tmux-plugins/tpm "$tpm"
        echo "  [>] tmux: TPM installed — press <prefix>+I in a tmux session to install plugins"
    fi
}

post_activate_vim() {
    ln -sf "${DOTFILES}/config/vim/.vimrc" "${HOME}/.vimrc"
    echo "  [>] vim: ~/.vimrc linked"

    if ! command -v vim &>/dev/null; then
        echo "  [!] vim: vim not installed, skipping plugin setup"
        return 0
    fi

    local bundle="${CONFIG}/vim/bundle/Vundle.vim"
    if [ ! -d "$bundle" ]; then
        echo "  [>] vim: installing Vundle..."
        git clone --quiet https://github.com/VundleVim/Vundle.vim.git "$bundle"
        vim +PluginInstall +qall
        echo "  [>] vim: plugins installed"
    fi

    local ansiesc="${HOME}/.vim_runtime/sources_non_forked/vim-plugin-AnsiEsc"
    if [ ! -d "$ansiesc" ]; then
        echo "  [>] vim: installing vim-plugin-AnsiEsc..."
        mkdir -p "$(dirname "$ansiesc")"
        git clone --quiet https://github.com/powerman/vim-plugin-AnsiEsc.git "$ansiesc"
        echo "  [>] vim: vim-plugin-AnsiEsc installed"
    fi
}

deactivate() {
    local item="$1"
    local src="${ITEM_SRC[$item]}"
    local dst="${ITEM_DST[$item]}"

    if is_dotfiles_link "$dst" "$src"; then
        rm "$dst"
        if [ -e "${dst}_bkp" ]; then
            mv "${dst}_bkp" "$dst"
            echo "  [-] $item: deactivated, backup restored"
        else
            echo "  [-] $item: deactivated"
        fi
    elif [ -e "$dst" ] || [ -L "$dst" ]; then
        echo "  [!] $item: not a dotfiles link, leaving untouched"
    else
        echo "  [=] $item: not active"
    fi
    set_state "$item" "no"
}

setup_tools() {
    local tools_dir="${HOME}/tools"
    if [ -d "${tools_dir}/.git" ]; then
        echo "  [=] tools: already cloned at ${tools_dir}"
    elif [ -d "${tools_dir}" ]; then
        echo "  [>] tools: ${tools_dir} exists but is not a git repo — cloning into it..."
        git clone git@github.com:FernandoMarcon/utils.git "${tools_dir}_tmp" \
            && rsync -a --remove-source-files "${tools_dir}_tmp/" "${tools_dir}/" \
            && rm -rf "${tools_dir}_tmp"
        echo "  [>] tools: cloned"
    else
        echo "  [>] tools: cloning utils repo to ${tools_dir}..."
        git clone git@github.com:FernandoMarcon/utils.git "${tools_dir}"
        echo "  [>] tools: cloned"
    fi
}

setup_hosts() {
    local hosts_file="${DOTFILES}/config/etc/hosts"
    if [ ! -f "$hosts_file" ]; then
        echo "  [=] hosts: no ${hosts_file#"${DOTFILES}"/} — skipping"
        return
    fi
    if grep -q "# BEGIN DOTFILES" /etc/hosts 2>/dev/null; then
        echo "  [=] hosts: already applied"
        return
    fi
    echo "  [>] hosts: appending ${hosts_file} to /etc/hosts..."
    printf '\n' | sudo tee -a /etc/hosts > /dev/null
    echo "# BEGIN DOTFILES" | sudo tee -a /etc/hosts > /dev/null
    sudo tee -a /etc/hosts < "$hosts_file" > /dev/null
    echo "# END DOTFILES" | sudo tee -a /etc/hosts > /dev/null
    echo "  [+] hosts: applied"
}

apply_state_file() {
    echo "Applying state from $STATE_FILE ..."
    while IFS=' ' read -r item state _rest; do
        [[ -z "$item" || "$item" == \#* ]] && continue
        if [[ -v ITEM_SRC[$item] ]]; then
            if [ "$state" = "yes" ]; then
                activate "$item"
            elif [ "$state" = "no" ]; then
                deactivate "$item"
            fi
        fi
    done < "$STATE_FILE"
    [ "$LINKS_ONLY" -eq 1 ] && return 0
    setup_tools
    setup_hosts
}

usage() {
    echo "Usage:"
    echo "  dotfiles.sh              apply current state from $STATE_FILE, then ~/tools and /etc/hosts"
    echo "  dotfiles.sh --links      apply state links only (no ~/tools, /etc/hosts or plugin installs)"
    echo "  dotfiles.sh [item ...]   activate specific items"
    echo ""
    echo "Available items: ${ALL_ITEMS[*]} tools"
}

init_state_file

if [ "${1:-}" = "--links" ]; then
    LINKS_ONLY=1
    apply_state_file
elif [ $# -eq 0 ]; then
    apply_state_file
else
    case "$1" in
        -h|--help) usage; exit 0 ;;
    esac

    for item in "$@"; do
        if [ "$item" = "tools" ]; then
            setup_tools
        elif [[ -v ITEM_SRC[$item] ]]; then
            activate "$item"
        else
            echo "  [!] Unknown item: '$item'"
            echo "      Available: ${ALL_ITEMS[*]} tools"
        fi
    done
fi

