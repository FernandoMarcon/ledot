#!/bin/bash
# Stream cava as bar characters, one line per frame.
# Feeds waybar's "custom/cava" module (PPA waybar lacks the built-in cava module).

bars=( "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" )

# sed "dictionary": strip separators, map level 0-7 to a bar
dict="s/;//g;"
for i in "${!bars[@]}"; do
    dict+="s/$i/${bars[$i]}/g;"
done

config_file="${XDG_RUNTIME_DIR:-/tmp}/waybar_cava_config"
cat > "$config_file" << EOF
[general]
bars = 14
framerate = 30

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

cava -p "$config_file" | sed -u "$dict"
