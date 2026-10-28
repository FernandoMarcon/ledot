#!/usr/bin/env bash
# Creates persistent tmux sessions on startup (called by i3)

declare -A SESSIONS
SESSIONS[dotfiles]="$HOME/.dotfiles"
SESSIONS[tools]="$HOME/tools"

for session in dotfiles tools; do
    dir="${SESSIONS[$session]}"
    if ! tmux has-session -t "$session" 2>/dev/null; then
        tmux new-session -d -s "$session" -c "$dir"
    fi
done
