#!/bin/bash
# second-brain.sh → Second Brain workspace (second-brain/setup.sh); Obsidian itself: setup/extra.sh
# Usage: bash ~/ledot/setup/second-brain.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

SECOND_BRAIN_SETUP="${DOTFILES}/second-brain/setup.sh"

[ -d "$DOTFILES" ] || die "ledot not found at $DOTFILES"

# ── Obsidian (optional app: setup/extra.sh) ──────────────────────────────────
if dpkg -s obsidian &>/dev/null; then
    track_detected obsidian "$(dpkg-query -W -f='${Version}' obsidian)"
else
    note "Obsidian isn't installed — the vaults work without it; to add it: bash ~/ledot/setup/extra.sh"
fi

# ── Second Brain workspace ───────────────────────────────────────────────────
if [ -f "$SECOND_BRAIN_SETUP" ]; then
    info "Running second-brain/setup.sh..."
    bash "$SECOND_BRAIN_SETUP"
    info "Second Brain setup complete"
else
    warn "second-brain/setup.sh not found — skipping"
    warn "If second-brain is a separate repo, clone it first:"
    warn "  git clone git@github.com:FernandoMarcon/second-brain.git $DOTFILES/second-brain"
fi
