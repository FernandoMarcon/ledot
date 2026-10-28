#!/bin/bash
# Print the network interface currently routing internet traffic.
# Exit 1 (no output) when offline.

iface="$(ip route get 1.1.1.1 2>/dev/null | awk '{ for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit } }')"

[[ -n "$iface" ]] || exit 1
echo "$iface"
