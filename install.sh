#!/bin/bash
# install.sh → run setup steps in order (each step is setup/<step>.sh)
# Usage:
#   install.sh                 full setup: bootstrap → CLI lists → [desktop lists] → dotfiles → second-brain → syncthing
#   install.sh server          headless:   bootstrap → CLI lists → dotfiles
#   install.sh <step> [...]    run specific steps, e.g. install.sh dev web
#   install.sh --list          show available steps

set -euo pipefail

DISTRO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup"
source "${DISTRO}/lib/common.sh"

CLI_STEPS=(minimal network files dev tools)
GUI_STEPS=(desktop display audio bluetooth media web system apps)

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
        run dotfiles second-brain syncthing
        ;;
    server)
        run bootstrap "${CLI_STEPS[@]}" dotfiles
        ;;
    -l|--list)
        echo "Steps (setup/<step>.sh):"
        for f in "${DISTRO}"/*.sh; do
            step="$(basename "$f" .sh)"
            printf "  %-14s %s\n" "$step" "$(sed -n '2s/^# [^ ]* — //p' "$f")"
        done
        exit 0
        ;;
    -h|--help)
        sed -n '2,7s/^# \{0,1\}//p' "$0"
        exit 0
        ;;
    *)
        run "$@"
        ;;
esac

echo ""
info "Done."
