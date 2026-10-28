#!/bin/bash
# Print current player as waybar custom-module JSON. No player: no output (module hides).

max_length=35

text="$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null)" || exit 0
tooltip="$(playerctl metadata --format '{{playerName}}: {{artist}} - {{title}}' 2>/dev/null)"

# Truncate long titles
if (( ${#text} > max_length )); then
    text="${text:0:max_length-3}..."
fi

# jq escapes quotes/backslashes in titles
jq -cn --arg text "$text" --arg tooltip "$tooltip" '{text: $text, tooltip: $tooltip}'
