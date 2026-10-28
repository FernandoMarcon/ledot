#!/usr/bin/env bash
## Container entry-point.
##
## Env vars that control behaviour (set via docker run -e or compose):
##   MODE         xephyr (default) | vnc
##   DISPLAY      X display to use (auto-set in xephyr mode from host)
##   VNC_PORT     VNC port (default 5900)
##   NOVNC_PORT   noVNC web port (default 6080)
##   RESOLUTION   virtual screen resolution for VNC mode (default 1280x800)

set -euo pipefail

# sudo needs to resolve the container hostname — with --network=host Docker
# sets the hostname but doesn't add it to /etc/hosts, so sudo errors out.
if ! getent hosts "$(hostname)" &>/dev/null; then
    echo "127.0.0.1 $(hostname)" | sudo tee -a /etc/hosts > /dev/null
fi

MODE="${MODE:-xephyr}"
VNC_PORT="${VNC_PORT:-5900}"
NOVNC_PORT="${NOVNC_PORT:-6080}"
RESOLUTION="${RESOLUTION:-1280x800}"

# ── dbus (needed by some apps) ────────────────────────────────────────────────
if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    eval "$(dbus-launch --sh-syntax)" 2>/dev/null || true
fi

# ── Mode: xephyr ─────────────────────────────────────────────────────────────
if [[ "$MODE" == "xephyr" ]]; then
    # DISPLAY is injected by the host launcher (e.g. :10).
    # Nothing to start here — just print a reminder and exec the command.
    echo ""
    echo "  ╔══════════════════════════════════════════════════╗"
    echo "  ║  Ubuntu i3 Test Container  [Xephyr mode]        ║"
    echo "  ║                                                  ║"
    echo "  ║  DISPLAY = ${DISPLAY:-<not set>}                            ║"
    echo "  ║                                                  ║"
    echo "  ║  The nested i3 session will appear in the        ║"
    echo "  ║  Xephyr window on your host desktop.             ║"
    echo "  ║                                                  ║"
    echo "  ║  Start the step-by-step runner:                  ║"
    echo "  ║    ~/distro/testing/scripts/step-runner.sh║"
    echo "  ╚══════════════════════════════════════════════════╝"
    echo ""
    exec "$@"
fi

# ── Mode: vnc ────────────────────────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║  Ubuntu i3 Test Container  [VNC mode]           ║"
echo "  ╚══════════════════════════════════════════════════╝"

# Virtual framebuffer
XVFB_DISPLAY=":99"
export DISPLAY="$XVFB_DISPLAY"

echo "  → Starting Xvfb on $XVFB_DISPLAY ($RESOLUTION)..."
Xvfb "$XVFB_DISPLAY" -screen 0 "${RESOLUTION}x24" -ac +extension GLX +render -noreset &
XVFB_PID=$!
sleep 0.8   # let Xvfb settle

# VNC server
echo "  → Starting x11vnc on port $VNC_PORT..."
x11vnc -display "$XVFB_DISPLAY" \
    -forever -nopw -shared \
    -rfbport "$VNC_PORT" \
    -quiet -bg \
    2>/dev/null

# noVNC web viewer (websockify bridges VNC → WebSocket)
NOVNC_DIR=""
for d in /usr/share/novnc /usr/local/share/novnc; do
    [[ -d "$d" ]] && { NOVNC_DIR="$d"; break; }
done

if [[ -n "$NOVNC_DIR" ]]; then
    echo "  → Starting noVNC on port $NOVNC_PORT..."
    websockify --web="$NOVNC_DIR" "$NOVNC_PORT" "localhost:$VNC_PORT" \
        --log-file=/tmp/novnc.log &
    echo ""
    echo "  ┌─────────────────────────────────────────────────┐"
    echo "  │  Open in browser:                               │"
    echo "  │    http://localhost:${NOVNC_PORT}/vnc.html              │"
    echo "  │  Or connect a VNC client to: localhost:${VNC_PORT}   │"
    echo "  └─────────────────────────────────────────────────┘"
else
    echo "  → noVNC not found. Connect a VNC client to localhost:${VNC_PORT}"
fi

echo ""
echo "  Start the step-by-step runner:"
echo "    ~/distro/testing/scripts/step-runner.sh"
echo ""

exec "$@"
