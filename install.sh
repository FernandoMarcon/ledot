#!/bin/bash
# install.sh → run setup steps in order (each step is setup/<step>.sh), by machine profile
# Usage:
#   install.sh                 setup for this machine's profile (asked once on a new machine, see --profile):
#                                personal: bootstrap → CLI → [desktop → [greeter]] → [carbon] → dotfiles → functions → second-brain → data → [R]
#                                server:   bootstrap → CLI → dotfiles → functions → data → [R]
#                                work:     asks before each step; never greeter, data/Syncthing or second-brain
#   install.sh server          the server steps, whatever the profile
#   install.sh <step> [...]    run specific steps, e.g. install.sh dev web
#   install.sh --profile [p]   show this machine's profile, or set it (personal, server, work)
#   install.sh --list          show available steps
#   install.sh --state         show tools installed outside apt/flatpak ($XDG_STATE_HOME/ledot/installs.tsv)

set -euo pipefail

DISTRO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup"
source "${DISTRO}/lib/common.sh"

CLI_STEPS=(minimal network files dev tools)
GUI_STEPS=(desktop display audio bluetooth media web system apps firewall)
# work: offered one by one, default no (shared PC, IT-managed: nothing personal unless you say so)
WORK_STEPS=(bootstrap "${CLI_STEPS[@]}" "${GUI_STEPS[@]}" dotfiles functions r)

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

run_profile() {
    local profile="$1" step
    export LEDOT_PROFILE="$profile"   # steps see the same profile without asking again
    info "Profile: ${profile} ($(hostname))"
    case "$profile" in
        personal)
            run bootstrap "${CLI_STEPS[@]}"
            if confirm "Install desktop packages (${GUI_STEPS[*]})?"; then
                run "${GUI_STEPS[@]}" greeter
            fi
            if is_carbon; then run carbon; fi
            run dotfiles functions second-brain data r
            ;;
        server)
            run bootstrap "${CLI_STEPS[@]}" dotfiles functions data r
            ;;
        work)
            for step in "${WORK_STEPS[@]}"; do
                if confirm_no "Run '${step}' ($(sed -En '2s/^# [^ ]* (→|—) //p' "${DISTRO}/${step}.sh" | cut -c1-70))?"; then
                    run "$step"
                fi
            done
            ;;
    esac
}

case "${1:-}" in
    "")
        run_profile "$(machine_profile)"
        ;;
    server)
        run_profile server
        ;;
    --profile)
        if [ -n "${2:-}" ]; then
            save_profile "$2"
            info "Profile for $(hostname): $2"
        else
            echo "$(machine_profile)  (${PROFILE_FILE})"
        fi
        exit 0
        ;;
    -l|--list)
        echo "Steps (setup/<step>.sh):"
        for f in "${DISTRO}"/*.sh; do
            step="$(basename "$f" .sh)"
            printf "  %-14s %s\n" "$step" "$(sed -En '2s/^# [^ ]* (→|—) //p' "$f")"
        done
        exit 0
        ;;
    --state)
        [ -f "$INSTALL_STATE" ] || { warn "No install state yet ($INSTALL_STATE)"; exit 0; }
        { printf 'NAME\tSOURCE\tVERSION\tDATE\n'; sort "$INSTALL_STATE"; } | column -t -s $'\t'
        exit 0
        ;;
    -h|--help)
        sed -n '2,13s/^# \{0,1\}//p' "$0"
        exit 0
        ;;
    *)
        run "$@"
        ;;
esac

echo ""
info "Done."
