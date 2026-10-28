#!/bin/bash
# (Re)start waybar with a config adapted to this machine's hardware.

DOTFILES="$HOME/.dotfiles"
SRC="$DOTFILES/bin"
WAYBAR="$DOTFILES/config/waybar"

config="$WAYBAR/config.jsonc"
runtime_config="${XDG_RUNTIME_DIR:-/tmp}/waybar/config.jsonc"
mkdir -p "$(dirname "$runtime_config")"

sed_args=(-e '')   # no-op script, so sed never treats $config as its script

# No battery: drop it from the modules list
"$SRC/has_battery.sh" || sed_args+=(-e '/^\s*"battery",\?\s*$/d')

# # Pin network module to the interface in use; offline: let waybar pick
# if iface="$("$SRC/get_net_interface.sh")"; then
#     sed_args+=(-e "s/\"interface\": \"[^\"]*\"/\"interface\": \"$iface\"/")
# else
#     sed_args+=(-e '/^\s*"interface":/d')
# fi

sed "${sed_args[@]}" "$config" > "$runtime_config"

pkill -x waybar
while pgrep -x waybar > /dev/null; do sleep 0.1; done

waybar -c "$runtime_config" -s "$WAYBAR/style.css" &
disown
