#!/usr/bin/env bash
## ╔══════════════════════════════════════════════════════╗
## ║  Archcraft i3wm → Ubuntu 24.04 Setup Orchestrator   ║
## ╚══════════════════════════════════════════════════════╝
##
## Usage:
##   ./setup.sh                    — run all modules in order
##   ./setup.sh 06_fonts           — run a single module by name
##   ./setup.sh 06_fonts 09_apps   — run specific modules in order
##
## Each module is idempotent and can be re-run safely.

set -euo pipefail

BASEDIR="${HOME}/.dotfiles/archive/distro-i3"
SCRIPT_DIR="${BASEDIR}/setup"
# archcraft-i3wm may live beside dotfiles or inside them
if [[ -d "${HOME}/distro/archcraft-i3wm" ]]; then
    REPO_DIR="${HOME}/distro/archcraft-i3wm"
else
    REPO_DIR="${BASEDIR}/archcraft-i3wm"
fi
export BASEDIR REPO_DIR SCRIPT_DIR

source "$SCRIPT_DIR/lib/common.sh"

# ── Module list (order matters) ───────────────────────────────────────────────
ALL_MODULES=(
    "00_preflight"      # sanity checks
    "01_repos"          # enable universe, apt update
    "02_xorg"           # X server + xinit + session
    "03_wm"             # i3, picom, dunst, polkit, power manager
    "04_polybar"        # polybar status bar
    "05_rofi"           # rofi launcher
    "06_fonts"          # Nerd Fonts (JetBrains, Symbols, Iosevka, archcraft)
    "07_audio"          # PipeWire + pulsemixer
    "08_terminal"       # alacritty + kitty
    "09_apps"           # thunar, geany, firefox, viewnior, yad
    "10_media"          # mpd, mpc, ffmpeg
    "11_network"        # NetworkManager + networkmanager-dmenu
    "12_utils"          # maim, xclip, light, ksuperkey, xcolor, pastel
    "13_lockscreen"     # i3lock + betterlockscreen
    "14_dotfiles"       # deploy ~/.config/i3 + Ubuntu patches
)

# ── Determine which modules to run ───────────────────────────────────────────
if [[ $# -gt 0 ]]; then
    RUN_MODULES=("$@")
else
    RUN_MODULES=("${ALL_MODULES[@]}")
fi

# ── Header ────────────────────────────────────────────────────────────────────
echo -e "\n\033[1;36m  Archcraft i3wm → Ubuntu 24.04\033[0m"
echo -e "  Repo  : $REPO_DIR"
echo -e "  Config: $HOME/.config/i3"
echo -e "  Modules to run: ${RUN_MODULES[*]}\n"

FAILED=()
START_TIME=$SECONDS

# GUI checkpoint: after 03_wm the minimum desktop is installed.
# If running a full suite, pause here so the user can log out/in
# to pick up group membership changes before continuing.
gui_checkpoint() {
    echo ""
    echo -e "\033[1;33m  ┌─────────────────────────────────────────────────────┐\033[0m"
    echo -e "\033[1;33m  │  GUI CHECKPOINT — X + i3 are now installed          │\033[0m"
    echo -e "\033[1;33m  │                                                     │\033[0m"
    echo -e "\033[1;33m  │  You can enter GUI mode right now:                  │\033[0m"
    echo -e "\033[1;33m  │    1. Log out (Ctrl-D or \`exit\`)                    │\033[0m"
    echo -e "\033[1;33m  │    2. Log back in on tty1 → startx launches i3      │\033[0m"
    echo -e "\033[1;33m  │                                                     │\033[0m"
    echo -e "\033[1;33m  │  To resume setup from this point, run:              │\033[0m"
    local remaining=("${@}")
    echo -e "\033[1;33m  │    ./setup.sh ${remaining[*]}\033[0m"
    echo -e "\033[1;33m  │                                                     │\033[0m"
    echo -e "\033[1;33m  └─────────────────────────────────────────────────────┘\033[0m"
    echo ""
    read -rp "  Press Enter to continue in TTY, or Ctrl-C to exit and log out now: "
}

# ── Run each module ───────────────────────────────────────────────────────────
GUI_CHECKPOINT_MODULE="03_wm"
GUI_CHECKPOINT_DONE=false

for module in "${RUN_MODULES[@]}"; do
    MODULE_SCRIPT="$SCRIPT_DIR/modules/${module}.sh"

    if [[ ! -f "$MODULE_SCRIPT" ]]; then
        log_error "Module not found: $MODULE_SCRIPT"
        FAILED+=("$module")
        continue
    fi

    if bash "$MODULE_SCRIPT"; then
        log_ok "[$module] done"
    else
        log_error "[$module] FAILED — continuing with remaining modules"
        FAILED+=("$module")
    fi

    # After 03_wm, when running a full suite, offer the GUI checkpoint
    if [[ "$module" == "$GUI_CHECKPOINT_MODULE" && "$GUI_CHECKPOINT_DONE" == false ]]; then
        # Only prompt when there are more modules left to run
        remaining_modules=()
        found=false
        for m in "${RUN_MODULES[@]}"; do
            "$found" && remaining_modules+=("$m")
            [[ "$m" == "$GUI_CHECKPOINT_MODULE" ]] && found=true
        done
        if [[ ${#remaining_modules[@]} -gt 0 ]]; then
            gui_checkpoint "${remaining_modules[@]}"
        fi
        GUI_CHECKPOINT_DONE=true
    fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
ELAPSED=$(( SECONDS - START_TIME ))
echo ""
echo -e "\033[1m  ── Summary ─────────────────────────────────────────\033[0m"
echo -e "  Elapsed : ${ELAPSED}s"
echo -e "  Modules : ${#RUN_MODULES[@]} run, ${#FAILED[@]} failed"
if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo -e "\033[0;31m  Failed  : ${FAILED[*]}\033[0m"
else
    echo -e "\033[0;32m  All modules completed successfully\033[0m"
fi

echo ""
echo -e "\033[1;33m  Next steps:\033[0m"
echo -e "  1. Log out and log back in (to pick up group changes)"
echo -e "  2. Run \033[1mstartx\033[0m to launch i3"
echo -e "  3. If brightness keys don't work: sudo chmod +s \$(which light)"
echo ""
