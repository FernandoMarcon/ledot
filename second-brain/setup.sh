#!/usr/bin/env bash
# second-brain/setup.sh
# Sets up ~/Vaults: clones vaults and links shared obsidian config.
# Idempotent — safe to run multiple times.
set -euo pipefail

VAULTS_DIR="$HOME/Vaults"
SHARED="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/obsidian-configs"

SHARED_FILES="appearance.json app.json hotkeys.json community-plugins.json core-plugins.json"
SHARED_DIRS="plugins snippets themes"
SHARED_GITIGNORE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gitignore"

# Vaults with known GitHub remotes.
# H4 and Piracaia have no remote — create them manually if needed.
declare -A VAULT_REMOTES=(
    [LGCM]="git@github.com:FernandoMarcon/LGCM"
    [concursos]="git@github.com:FernandoMarcon/concursos.git"
    [leiloes]="git@github.com:FernandoMarcon/leiloes.git"
    [projects]="git@github.com:FernandoMarcon/projects.git"
    [wiki]="git@github.com:FernandoMarcon/wiki.git"
)

# ── 1. Create ~/Vaults ────────────────────────────────────────────────────────
mkdir -p "$VAULTS_DIR"
echo "Vaults dir: $VAULTS_DIR"

# ── 2. Clone vaults (skip if already present) ────────────────────────────────
for vault in "${!VAULT_REMOTES[@]}"; do
    dest="$VAULTS_DIR/$vault"
    if [ -d "$dest/.git" ]; then
        echo "Skip clone (exists): $vault"
    else
        echo "Cloning $vault..."
        git clone "${VAULT_REMOTES[$vault]}" "$dest"
    fi
done

# ── 3. Link shared obsidian config into each vault ────────────────────────────
link_shared_config() {
    local vault_obs="$1"
    mkdir -p "$vault_obs"

    for f in $SHARED_FILES; do
        src="$SHARED/$f"
        target="$vault_obs/$f"
        [ -f "$src" ] || continue
        # Back up real file if not already a symlink
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mv "$target" "${target}.bak"
            echo "  Backed up: $f"
        fi
        ln -sf "$src" "$target"
    done

    for d in $SHARED_DIRS; do
        src="$SHARED/$d"
        target="$vault_obs/$d"
        [ -d "$src" ] || continue
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mv "$target" "${target}.bak"
            echo "  Backed up: $d/"
        fi
        ln -sf "$src" "$target"
    done
}

echo ""
echo "Linking shared config..."
for vault in "$VAULTS_DIR"/*/; do
    [ -d "$vault" ] || continue
    vault_obs="${vault}.obsidian"
    link_shared_config "$vault_obs"
    echo "  Linked: $(basename "${vault%/}")"
done

echo ""
echo "Linking shared .gitignore..."
for vault in "$VAULTS_DIR"/*/; do
    [ -d "$vault/.git" ] || continue
    target="${vault}.gitignore"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "${target}.bak"
        echo "  Backed up: $(basename "${vault%/}")/.gitignore"
    fi
    ln -sf "$SHARED_GITIGNORE" "$target"
    echo "  Linked: $(basename "${vault%/}")"
done

echo ""
echo "Done."
