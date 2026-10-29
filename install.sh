#!/bin/bash
# install.sh → run setup steps in order (each step is setup/<step>.sh)
# Usage:
#   install.sh                 full setup: bootstrap → CLI lists → [desktop lists] → [carbon] → dotfiles → second-brain → syncthing → [R packages]
#   install.sh server          headless:   bootstrap → CLI lists → dotfiles → [R packages]
#   install.sh <step> [...]    run specific steps, e.g. install.sh dev web
#   install.sh --list          show available steps
#   install.sh --state         show tools installed outside apt/flatpak ($XDG_STATE_HOME/ledot/installs.tsv)

set -euo pipefail

DISTRO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup"
source "${DISTRO}/lib/common.sh"

CLI_STEPS=(minimal network files dev tools)
GUI_STEPS=(desktop greeter display audio bluetooth media web system apps firewall)

is_carbon() { grep -q "X1 Carbon" /sys/class/dmi/id/product_version 2>/dev/null; }

run() {
    local step
    for step in "$@"; do
        [ -f "${DISTRO}/${step}.sh" ] || die "Unknown step: ${step} (see --list)"
    done
    for step in "$@"; do
        header "${step}"
        bash "${DISTRO}/${step}.sh"
    done
}

case "${1:-}" in
    "")
        run bootstrap "${CLI_STEPS[@]}"
        if confirm "Install desktop packages (${GUI_STEPS[*]})?"; then
            run "${GUI_STEPS[@]}"
        fi
        is_carbon && run carbon
        run dotfiles second-brain syncthing r
        ;;
    server)
        run bootstrap "${CLI_STEPS[@]}" dotfiles r
        ;;
    -l|--list)
        echo "Steps (setup/<step>.sh):"
        for f in "${DISTRO}"/*.sh; do
            step="$(basename "$f" .sh)"
            printf "  %-14s %s\n" "$step" "$(sed -n '2s/^# [^ ]* — //p' "$f")"
        done
        exit 0
        ;;
    --state)
        [ -f "$INSTALL_STATE" ] || { warn "No install state yet ($INSTALL_STATE)"; exit 0; }
        { printf 'NAME\tSOURCE\tVERSION\tDATE\n'; sort "$INSTALL_STATE"; } | column -t -s $'\t'
        exit 0
        ;;
    -h|--help)
        sed -n '2,8s/^# \{0,1\}//p' "$0"
        exit 0
        ;;
    *)
        run "$@"
        ;;
esac

echo ""
info "Done."
