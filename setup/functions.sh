#!/bin/bash
# functions.sh → pkgs/functions.list + everything functions/* need: PATH, data dirs, LLM prompts, dependency check
# Run after: dev (claude, gemini, docker) and dotfiles (~/.locales puts functions/ on PATH)
# Usage: bash ~/ledot/setup/functions.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

FUNCS="${DOTFILES}/functions"
PATTERNS="${DOTFILES}/patterns"

# Commands each function needs beyond coreutils (checked at the end)
declare -A DEPS=(
    [bwpick]="bw jq fzf wl-copy wl-paste"
    [calc]="awk"
    [clean_docker]="docker"
    [cleanpkg]="pacman"
    [fixsudo]=""
    [gsync]="git"
    [ms_to_hhmmss]=""
    [shebang]=""
    [json]="jq less"
    [mountencrypt]="cryptsetup mountpoint"
    [nmouse]="hyprctl"
    [note]="vim"
    [playlist_to_md]="yt-dlp"
    [query]="claude"
    [search]="jq w3m"
    [search_llm]="gemini"
    [srt]="yt-dlp wl-paste"
    [tunelcp]="ssh scp"
    [work-daily]="vim"
    [ymouse]="hyprctl"
)

install_list functions
install_ytdlp

# ── Executable bits ──────────────────────────────────────────────────────────
chmod +x "${FUNCS}"/*
info "functions/* executable"

# ── PATH: ~/.locales adds functions/ and patterns/ ───────────────────────────
LOCALES_SRC="${DOTFILES}/config/locales"
if [ "$(readlink -f "${HOME}/.locales" 2>/dev/null)" = "$(readlink -f "$LOCALES_SRC")" ]; then
    info "~/.locales linked (functions/ on PATH)"
else
    bash "${DOTFILES}/setup/dotfiles.sh" locales
fi

# ── Per-function data ────────────────────────────────────────────────────────
# query: Claude reads its rules from patterns/query.md and logs to ~/.history/query
[ -f "${PATTERNS}/query.md" ] || die "query: ${PATTERNS}/query.md missing"
mkdir -p "${HOME}/.history/query"
info "query: ~/.history/query ready"

# tunelcp: copies land in ~/tunel; hops through mentat (offers to set up `ssh mentat`; not needed on mentat)
mkdir -p "${HOME}/tunel"
if is_hub; then
    info "tunelcp: this is ${HUB_HOST} — no hop needed"
elif has_hub_ssh_entry; then
    info "tunelcp: 'Host ${HUB_HOST}' in ~/.ssh/config"
else
    note "tunelcp hops through ${HUB_HOST}: needs 'ssh ${HUB_HOST}' without a password"
    ensure_hub_ssh || note "tunelcp: skipped — set up later with: install.sh functions"
fi

# ── Dependency check ─────────────────────────────────────────────────────────
missing=0
for fn in $(printf '%s\n' "${!DEPS[@]}" | sort); do
    [ -f "${FUNCS}/${fn}" ] || continue
    for cmd in ${DEPS[$fn]}; do
        command -v "$cmd" &>/dev/null || { warn "${fn}: '${cmd}' not found"; missing=1; }
    done
done
for f in "${FUNCS}"/*; do
    [[ -v DEPS[$(basename "$f")] ]] || note "$(basename "$f"): no deps listed in setup/functions.sh"
done

[ "$missing" -eq 0 ] && info "All function dependencies found" \
    || note "claude/gemini/docker → install.sh dev; bw → tools; hyprctl → desktop; pacman (cleanpkg) is Arch-only"
