#!/bin/bash
# Exit 0 if the machine has a system battery, 1 otherwise.
# Peripheral batteries (wireless mice, headsets) report scope=Device and are ignored.

for supply in /sys/class/power_supply/*; do
    [[ "$(cat "$supply/type" 2>/dev/null)" == "Battery" ]] || continue
    [[ "$(cat "$supply/scope" 2>/dev/null)" == "Device" ]] && continue
    exit 0
done

exit 1
