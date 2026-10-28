#!/bin/bash
# bootstrap.sh — SSH key, GitHub access, git identity
# Run after: the manual first steps in setup/README.md (update, install gh, auth, clone)
# Usage: bash ~/.dotfiles/setup/bootstrap.sh

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GH_USER="FernandoMarcon"
SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_KEY_TITLE="$(hostname)-$(date +%Y%m%d)"

# =============================================================================
# PREREQUISITES
# =============================================================================
header "Prerequisites"
command -v gh  &>/dev/null || die "gh CLI not found. Complete the first steps in setup/README.md."
command -v git &>/dev/null || die "git not found. Run: sudo apt install git"
[ -d "$DOTFILES" ]         || die ".dotfiles not found at $DOTFILES. Complete the first steps in setup/README.md."
info "Prerequisites OK"

# =============================================================================
# 1. SSH KEY — partial
# =============================================================================
header "1/5  SSH Key Generation  [partial]"
note "Generates an Ed25519 SSH key for GitHub authentication."
echo ""

if [ -f "$SSH_KEY" ]; then
    info "SSH key already exists at $SSH_KEY — skipping"
elif confirm "Generate SSH key?"; then
    read -rp "  Email for SSH key: " GIT_EMAIL
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N ""
    info "SSH key generated"
fi

# =============================================================================
# 2. ADD SSH KEY TO GITHUB — partial
# =============================================================================
header "2/5  Add SSH Key to GitHub  [partial]"
note "Uploads the public key to your GitHub account."
echo ""

if [ ! -f "${SSH_KEY}.pub" ]; then
    warn "No public key found — skipping"
elif confirm "Add SSH key to GitHub?"; then
    gh ssh-key add "${SSH_KEY}.pub" --title "$SSH_KEY_TITLE" \
        && info "SSH key added (title: $SSH_KEY_TITLE)" \
        || {
            warn "Could not add key automatically — add it manually at github.com/settings/keys"
            echo ""
            cat "${SSH_KEY}.pub"
            echo ""
            confirm "Done adding key manually? Continue?"
        }
fi

# =============================================================================
# 3. TEST SSH CONNECTION — automated
# =============================================================================
header "3/5  Test SSH Connection  [automated]"
echo ""

if ssh -T git@github.com -o StrictHostKeyChecking=accept-new 2>&1 | grep -q "successfully authenticated"; then
    info "SSH connection to GitHub OK"
else
    warn "SSH test inconclusive — proceeding anyway"
fi

# =============================================================================
# 4. SWITCH .DOTFILES REMOTE TO SSH — automated
# =============================================================================
header "4/5  Switch .dotfiles Remote to SSH  [automated]"
echo ""

CURRENT_REMOTE=$(git -C "$DOTFILES" remote get-url origin 2>/dev/null || echo "")
if [[ "$CURRENT_REMOTE" == git@* ]]; then
    info ".dotfiles remote is already SSH — skipping"
elif confirm "Switch .dotfiles remote to SSH?"; then
    git -C "$DOTFILES" remote set-url origin "git@github.com:${GH_USER}/.dotfiles.git"
    info ".dotfiles remote switched to SSH"
fi

# =============================================================================
# 5. GIT IDENTITY — partial
# =============================================================================
header "5/5  Git Identity  [partial]"
note "Sets global git user.name and user.email."
echo ""

if [ -n "$(git config --global user.name 2>/dev/null)" ] && \
   [ -n "$(git config --global user.email 2>/dev/null)" ]; then
    info "Git identity already set — skipping"
    note "  name:  $(git config --global user.name)"
    note "  email: $(git config --global user.email)"
elif confirm "Configure git identity?"; then
    read -rp "  Git name:  " GIT_NAME
    read -rp "  Git email: " GIT_EMAIL_CONF
    git config --global user.name  "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL_CONF"
    info "Git identity configured"
fi

# =============================================================================
echo ""
info "Bootstrap complete!"
