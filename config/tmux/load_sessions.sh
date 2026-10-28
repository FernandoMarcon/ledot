#!/bin/bash

TMUXDIR="${HOME}/ledot/config/tmux"
SESSIONS="${TMUXDIR}/sessions"

while IFS=',' read -r SESSION SESSION_PATH; do
    [[ -z "$SESSION" ]] && continue
    SESSION_PATH="${SESSION_PATH/\$HOME/$HOME}"
    [[ ! -d "$SESSION_PATH" ]] && continue

    tmux has-session -t "$SESSION" 2>/dev/null && continue

    echo -e "\t[ TMUX ] $SESSION → $SESSION_PATH"
    tmux new -s "$SESSION" -c "$SESSION_PATH" -d

done < "$SESSIONS"
