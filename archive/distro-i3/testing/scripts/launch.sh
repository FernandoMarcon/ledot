#!/usr/bin/env bash
## Host-side launcher.
## Builds the Docker image and starts the test container in Xephyr or VNC mode.
##
## Usage:
##   ./launch.sh           — Xephyr mode (default, requires running X)
##   ./launch.sh vnc       — VNC mode (self-contained, browser at :6080)
##   ./launch.sh build     — rebuild image only
##   ./launch.sh clean     — stop + remove container and image

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$TESTING_DIR/.." && pwd)"   # distro/

IMAGE="ubuntu-i3-test"
CONTAINER="ubuntu-i3-test"
XEPHYR_DISPLAY=":10"
XEPHYR_RESOLUTION="1280x800"
VNC_PORT="5900"
NOVNC_PORT="6080"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()  { echo -e "${CYAN}  → $*${RESET}"; }
ok()    { echo -e "${GREEN}  ✔ $*${RESET}"; }
warn()  { echo -e "${YELLOW}  ⚠ $*${RESET}"; }
die()   { echo -e "${RED}  ✖ $*${RESET}" >&2; exit 1; }

# ── Helpers ───────────────────────────────────────────────────────────────────
build_image() {
    info "Building Docker image: ${IMAGE}..."
    docker build \
        --network=host \
        --build-arg UID="$(id -u)" \
        -t "$IMAGE" \
        "$TESTING_DIR"
    ok "Image built: ${IMAGE}"
}

ensure_image() {
    if ! docker image inspect "$IMAGE" &>/dev/null; then
        build_image
    else
        ok "Image already exists: ${IMAGE}  (run './launch.sh build' to rebuild)"
    fi
}

stop_existing() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        warn "Removing existing container: ${CONTAINER}"
        docker rm -f "$CONTAINER" &>/dev/null
    fi
}

# ── Mode: xephyr ─────────────────────────────────────────────────────────────
launch_xephyr() {
    which Xephyr &>/dev/null || die "Xephyr not found. Install xorg-server-xephyr (Arch: sudo pacman -S xorg-server-xephyr)"
    [[ -n "${DISPLAY:-}" ]] || die "DISPLAY is not set — is your X session running?"

    # Find a free display number starting at 10
    XDISP="$XEPHYR_DISPLAY"
    while [[ -S "/tmp/.X11-unix/X${XDISP#:}" ]]; do
        XDISP=":$(( ${XDISP#:} + 1 ))"
    done

    info "Starting Xephyr on ${XDISP} (${XEPHYR_RESOLUTION})..."
    Xephyr "${XDISP}" \
        -screen "${XEPHYR_RESOLUTION}" \
        -resizeable \
        -title "Ubuntu i3 Test — ${XDISP}" \
        &
    XEPHYR_PID=$!
    sleep 0.5   # let Xephyr initialize

    # Allow local connections from Docker (no auth needed for test env)
    xhost +local: &>/dev/null
    ok "Xephyr running (PID ${XEPHYR_PID})"

    stop_existing
    ensure_image

    info "Starting container '${CONTAINER}' in Xephyr mode..."
    echo ""
    echo -e "${BOLD}  Inside the container, run:${RESET}"
    echo -e "    ${CYAN}~/distro/testing/scripts/step-runner.sh${RESET}"
    echo ""

    # Run container interactively
    docker run -it \
        --name "$CONTAINER" \
        --hostname ubuntu-i3-test \
        --network=host \
        --shm-size=256m \
        -e MODE=xephyr \
        -e DISPLAY="${XDISP}" \
        -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
        -v "${REPO_DIR}:/home/tester/distro" \
        "$IMAGE"

    # Cleanup Xephyr when container exits
    kill "$XEPHYR_PID" 2>/dev/null && ok "Xephyr stopped"
    xhost -local: &>/dev/null || true
}

# ── Mode: vnc ────────────────────────────────────────────────────────────────
launch_vnc() {
    stop_existing
    ensure_image

    info "Starting container '${CONTAINER}' in VNC mode..."
    echo ""
    echo -e "${BOLD}  Connect:${RESET}"
    echo -e "    Browser  → ${CYAN}http://localhost:${NOVNC_PORT}/vnc.html${RESET}"
    echo -e "    VNC app  → ${CYAN}localhost:${VNC_PORT}${RESET}"
    echo ""
    echo -e "${BOLD}  Inside the container, run:${RESET}"
    echo -e "    ${CYAN}~/distro/testing/scripts/step-runner.sh${RESET}"
    echo ""

    docker run -it \
        --name "$CONTAINER" \
        --hostname ubuntu-i3-test \
        --network=host \
        --shm-size=256m \
        -e MODE=vnc \
        -e VNC_PORT="${VNC_PORT}" \
        -e NOVNC_PORT="${NOVNC_PORT}" \
        -v "${REPO_DIR}:/home/tester/distro" \
        "$IMAGE"
}

# ── Mode: clean ───────────────────────────────────────────────────────────────
do_clean() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        docker rm -f "$CONTAINER"
        ok "Container removed: ${CONTAINER}"
    else
        warn "No container named ${CONTAINER} found"
    fi

    if docker image inspect "$IMAGE" &>/dev/null; then
        docker rmi "$IMAGE"
        ok "Image removed: ${IMAGE}"
    else
        warn "No image named ${IMAGE} found"
    fi
}

# ── Mode: exec ────────────────────────────────────────────────────────────────
# Re-attach to a running container (e.g. after detaching with Ctrl-P Ctrl-Q)
do_exec() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        die "Container '${CONTAINER}' is not running. Use './launch.sh' to start it."
    fi
    docker exec -it "$CONTAINER" bash --login
}

# ── Checkpoint ───────────────────────────────────────────────────────────────
# Commit the current container state as a tagged image so you can roll back.
do_checkpoint() {
    local tag="${1:-checkpoint-$(date +%Y%m%d-%H%M%S)}"
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        die "Container '${CONTAINER}' not found."
    fi
    docker commit "$CONTAINER" "${IMAGE}:${tag}"
    ok "Checkpoint saved as ${IMAGE}:${tag}"
    echo ""
    echo "  To restore this checkpoint later:"
    echo "    docker run -it --name ${CONTAINER} ${IMAGE}:${tag}"
}

# ── Entry point ───────────────────────────────────────────────────────────────
case "${1:-xephyr}" in
    xephyr)     launch_xephyr ;;
    vnc)        launch_vnc ;;
    build)      build_image ;;
    clean)      do_clean ;;
    exec)       do_exec ;;
    checkpoint) do_checkpoint "${2:-}" ;;
    *)          echo "Usage: $0 [xephyr|vnc|build|clean|exec|checkpoint [tag]]"; exit 1 ;;
esac
