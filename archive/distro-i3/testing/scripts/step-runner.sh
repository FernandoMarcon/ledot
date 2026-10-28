#!/usr/bin/env bash
## Step-by-step module runner — run this INSIDE the container.
##
## Usage:
##   ./step-runner.sh              — walk through all modules interactively
##   ./step-runner.sh 06_fonts     — start from a specific module
##   ./step-runner.sh --from 06    — start from module index 06
##   ./step-runner.sh --list       — print modules and exit

set -euo pipefail

# ── Paths ─────────────────────────────────────────────────────────────────────
RICE_DIR="${HOME}/distro"
SETUP_DIR="${RICE_DIR}/setup"

if [[ ! -d "$SETUP_DIR" ]]; then
    echo "ERROR: $SETUP_DIR not found."
    echo "Make sure the repo is mounted at ~/distro"
    exit 1
fi

source "$SETUP_DIR/lib/common.sh"

# ── Module list (mirrors setup.sh) ───────────────────────────────────────────
ALL_MODULES=(
    "00_preflight"
    "01_repos"
    "02_xorg"
    "03_wm"
    "04_polybar"
    "05_rofi"
    "06_fonts"
    "07_audio"
    "08_terminal"
    "09_apps"
    "10_media"
    "11_network"
    "12_utils"
    "13_lockscreen"
    "14_dotfiles"
)

# ── Smoke tests: run after a module to confirm key binaries/configs landed ────
declare -A SMOKE_TESTS=(
    ["00_preflight"]=""
    ["01_repos"]="apt-cache policy 2>/dev/null | grep -q universe && echo 'universe: OK'"
    ["02_xorg"]="which xinit && which Xvfb && echo 'xorg: OK'"
    ["03_wm"]="i3 --version && picom --version 2>&1 | head -1 && dunst --version 2>&1 | head -1"
    ["04_polybar"]="polybar --version"
    ["05_rofi"]="rofi -version"
    ["06_fonts"]="fc-list | grep -i 'JetBrains' | head -1 || echo 'JetBrains not found yet (cache may need refresh)'"
    ["07_audio"]="which pulsemixer && pulsemixer --version"
    ["08_terminal"]="alacritty --version && kitty --version 2>&1 | head -1"
    ["09_apps"]="which thunar && which geany && which firefox"
    ["10_media"]="mpd --version | head -1 && mpc --version | head -1 && ffmpeg -version 2>&1 | head -1"
    ["11_network"]="nmcli --version && which networkmanager_dmenu"
    ["12_utils"]="which maim && which xclip && which xdotool && which light && which ksuperkey"
    ["13_lockscreen"]="which betterlockscreen && which i3lock"
    ["14_dotfiles"]="[[ -f ~/.config/i3/config ]] && echo 'i3 config: OK' && [[ -f ~/.config/i3/theme/wallpaper ]] && echo 'wallpaper: OK'"
)

# ── Launch suggestions: what to try after installing a module ─────────────────
declare -A LAUNCH_HINTS=(
    ["03_wm"]="Launch a minimal i3 session to test WM:\n  DISPLAY=\$DISPLAY i3 &\n  (appear in Xephyr / VNC window)"
    ["04_polybar"]="Verify Polybar binary works (config is deployed later in 14_dotfiles):\n  polybar --version"
    ["05_rofi"]="Test Rofi:\n  rofi -show run"
    ["08_terminal"]="Restart i3 to pick up Alacritty, then open a terminal:\n  killall i3 2>/dev/null; sleep 1; DISPLAY=\$DISPLAY i3 &\n  (wait for i3 to start, then Super+Return)"
    ["14_dotfiles"]="Launch the full i3 session:\n  DISPLAY=\$DISPLAY i3"
)

# ── Helpers ───────────────────────────────────────────────────────────────────
PASSED=()
FAILED=()
SKIPPED=()

print_status() {
    echo ""
    echo -e "${BOLD}  ── Session Status ─────────────────────────────────${RESET}"
    [[ ${#PASSED[@]}  -gt 0 ]] && echo -e "${GREEN}  Passed : ${PASSED[*]}${RESET}"
    [[ ${#SKIPPED[@]} -gt 0 ]] && echo -e "${YELLOW}  Skipped: ${SKIPPED[*]}${RESET}"
    [[ ${#FAILED[@]}  -gt 0 ]] && echo -e "${RED}  Failed : ${FAILED[*]}${RESET}"
    echo ""
}

run_smoke_test() {
    local module="$1"
    local test_cmd="${SMOKE_TESTS[$module]:-}"
    [[ -z "$test_cmd" ]] && return
    echo ""
    log_info "Smoke test:"
    if eval "$test_cmd" 2>&1 | sed 's/^/    /'; then
        log_ok "Smoke test passed"
    else
        log_warn "Smoke test had non-zero exit — check output above"
    fi
}

show_launch_hint() {
    local module="$1"
    local hint="${LAUNCH_HINTS[$module]:-}"
    [[ -z "$hint" ]] && return
    echo ""
    echo -e "${CYAN}  ── Try it out ─────────────────────────────────────${RESET}"
    echo -e "$hint" | sed 's/^/  /'
}

prompt_continue() {
    local module="$1"
    echo ""
    echo -ne "${BOLD}  Run ${CYAN}${module}${RESET}${BOLD} ?  [Y=yes / s=skip / q=quit / r=run all remaining] ${RESET}"
    read -r answer
    case "${answer,,}" in
        s)        return 1 ;;
        q)        echo ""; log_info "Stopping."; print_status; exit 0 ;;
        r)        echo "__run_all__"; return 0 ;;
        *)        return 0 ;;   # Y or Enter
    esac
}

# ── Argument parsing ──────────────────────────────────────────────────────────
START_MODULE=""
RUN_ALL=false

case "${1:-}" in
    --list)
        echo "Available modules:"
        for m in "${ALL_MODULES[@]}"; do printf "  %s\n" "$m"; done
        exit 0
        ;;
    --from)
        START_MODULE="${2:-}"
        shift 2
        ;;
    "")
        ;;
    *)
        START_MODULE="$1"
        shift
        ;;
esac

# Build the list of modules to process
MODULES_TO_RUN=()
STARTED=false
for m in "${ALL_MODULES[@]}"; do
    if [[ -z "$START_MODULE" || "$m" == *"$START_MODULE"* ]]; then
        STARTED=true
    fi
    $STARTED && MODULES_TO_RUN+=("$m")
done

if [[ ${#MODULES_TO_RUN[@]} -eq 0 ]]; then
    log_error "No module matched '$START_MODULE'"
    exit 1
fi

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}  ║  Archcraft i3wm → Ubuntu 24.04              ║${RESET}"
echo -e "${BOLD}${CYAN}  ║  Step-by-step module tester                 ║${RESET}"
echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════╝${RESET}"
echo -e "  Modules queued: ${#MODULES_TO_RUN[@]}"
echo -e "  DISPLAY = ${DISPLAY:-<not set>}"
echo ""
echo -e "  Controls: ${GREEN}Enter/Y${RESET}=run  ${YELLOW}s${RESET}=skip  ${CYAN}r${RESET}=run all remaining  ${RED}q${RESET}=quit"
echo ""

# ── Main loop ─────────────────────────────────────────────────────────────────
for module in "${MODULES_TO_RUN[@]}"; do
    MODULE_SCRIPT="$SETUP_DIR/modules/${module}.sh"

    if [[ ! -f "$MODULE_SCRIPT" ]]; then
        log_warn "Module script not found: $MODULE_SCRIPT — skipping"
        SKIPPED+=("$module")
        continue
    fi

    # Prompt (unless we're in run-all mode)
    if ! $RUN_ALL; then
        answer=$(prompt_continue "$module" || echo "skip")
        if [[ "$answer" == "skip" || "$answer" == "1" ]]; then
            SKIPPED+=("$module")
            continue
        fi
        if [[ "$answer" == "__run_all__" ]]; then
            RUN_ALL=true
        fi
    fi

    # Run the module
    log_section "Running: $module"
    START_T=$SECONDS
    if bash "$MODULE_SCRIPT"; then
        ELAPSED=$(( SECONDS - START_T ))
        log_ok "$module completed in ${ELAPSED}s"
        PASSED+=("$module")
        run_smoke_test "$module"
        show_launch_hint "$module"
    else
        ELAPSED=$(( SECONDS - START_T ))
        log_error "$module FAILED after ${ELAPSED}s"
        FAILED+=("$module")
        echo ""
        echo -ne "${BOLD}  Module failed. Continue anyway? [Y/n] ${RESET}"
        read -r fail_answer
        [[ "${fail_answer,,}" == "n" ]] && { print_status; exit 1; }
    fi

    echo ""
    echo -ne "  ${BOLD}Press Enter to continue...${RESET}"
    $RUN_ALL || read -r
done

# ── Final summary ─────────────────────────────────────────────────────────────
print_status

if [[ ${#FAILED[@]} -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}  All modules completed.${RESET}"
    echo ""
    echo -e "  To launch i3:   ${BOLD}DISPLAY=\$DISPLAY i3${RESET}"
    echo -e "  Config lives at: ${BOLD}~/.config/i3/${RESET}"
else
    echo -e "${YELLOW}  Setup finished with ${#FAILED[@]} failure(s).${RESET}"
    echo -e "  Retry a failed module:"
    for f in "${FAILED[@]}"; do
        echo -e "    ${BOLD}bash $SETUP_DIR/modules/${f}.sh${RESET}"
    done
fi
echo ""
