#!/bin/bash
# second-brain.sh → Obsidian + Second Brain workspace (second-brain/setup.sh)
# Usage: bash ~/ledot/setup/second-brain.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

SECOND_BRAIN_SETUP="${DOTFILES}/second-brain/setup.sh"

[ -d "$DOTFILES" ] || die "ledot not found at $DOTFILES"

# ── Obsidian (latest .deb from GitHub releases) ──────────────────────────────
if dpkg -s obsidian &>/dev/null; then
    info "Obsidian already installed — skipping"
    track_detected obsidian "$(dpkg-query -W -f='${Version}' obsidian)"
elif confirm "Install Obsidian?"; then
    OBSIDIAN_VERSION=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v')
    note "Latest version: ${OBSIDIAN_VERSION}"
    wget -q "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/obsidian_${OBSIDIAN_VERSION}_amd64.deb" \
        -O /tmp/obsidian.deb
    sudo apt-get install -y /tmp/obsidian.deb
    rm /tmp/obsidian.deb
    track_install obsidian "github:obsidianmd/obsidian-releases (.deb)" "${OBSIDIAN_VERSION}"
    info "Obsidian v${OBSIDIAN_VERSION} installed"
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
