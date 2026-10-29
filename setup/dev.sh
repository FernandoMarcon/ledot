#!/bin/bash
# dev.sh → pkgs/dev.list: languages and dev tooling
# Also: NodeSource repo, Docker, AI CLIs (Claude Code, Gemini, Antigravity), Miniconda + 'tools' env,
#       radian, fabric, Singularity (R packages: setup/r.sh)
# Usage: bash ~/ledot/setup/dev.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ── NodeSource repo (Node.js v24) ────────────────────────────────────────────
node_major=0
command -v node &>/dev/null && node_major=$(node --version | tr -d 'v' | cut -d. -f1)
if [ "$node_major" -lt 24 ] && [ ! -f /etc/apt/sources.list.d/nodesource.list ]; then
    info "Adding NodeSource repo (Node.js v24)..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | sudo gpg --dearmor --yes -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" \
        | sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null
    sudo apt-get update -qq
fi

install_list dev

# ── Docker (official repo) ───────────────────────────────────────────────────
header "Docker"
if command -v docker &>/dev/null && dpkg -s docker-ce &>/dev/null; then
    info "Docker CE already installed — skipping"
elif confirm "Install Docker from Docker's official repo?"; then
    sudo bash "${DOTFILES}/bin/docker_install.sh"
fi

# ── Claude Code ──────────────────────────────────────────────────────────────
header "Claude Code"
if command -v claude &>/dev/null; then
    info "Claude Code already installed — skipping"
    track_detected claude-code "$(claude --version 2>/dev/null | awk '{ print $1 }')"
elif confirm "Install Claude Code?"; then
    curl -fsSL https://claude.ai/install.sh | bash
    track_install claude-code "curl:claude.ai/install.sh" "$("$HOME/.local/bin/claude" --version 2>/dev/null | awk '{ print $1 }')"
    grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc \
        || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    info "Claude Code installed. Reload shell: source ~/.bashrc"
fi

SKILLS=(
    "JuliusBrussee/caveman"
    "Lum1104/Understand-Anything"
    "obra/superpowers"
    "awesome-skills/code-review-skill"
    "thedotmack/claude-mem"
)
note "Claude Code skills: ${SKILLS[*]}"
if confirm "Install all Claude Code skills?"; then
    command -v npx &>/dev/null || die "npx not found — nodejs (dev.list) failed to install"
    installed_skills=$(npx -y skills list -g --json 2>/dev/null || true)
    for skill in "${SKILLS[@]}"; do
        if grep -qF "\"source\": \"${skill}\"" <<< "${installed_skills}"; then
            info "${skill} already installed — skipping"
            track_detected "skill:${skill}"
            continue
        fi
        echo "  Installing ${skill}..."
        npx -y skills add "${skill}" -g -a claude-code -y \
            && track_install "skill:${skill}" "npx:skills" \
            && info "${skill} installed" \
            || warn "${skill} failed — retry: npx skills add ${skill} -g -a claude-code"
    done
fi

# ── Gemini CLI ───────────────────────────────────────────────────────────────
header "Gemini CLI"
if command -v gemini &>/dev/null; then
    info "Gemini CLI already installed — skipping"
    track_detected gemini-cli "$(gemini --version 2>/dev/null)"
elif confirm "Install Gemini CLI (npm global)?"; then
    command -v npm &>/dev/null || die "npm not found — nodejs (dev.list) failed to install"
    sudo npm install -g @google/gemini-cli
    track_install gemini-cli "npm:@google/gemini-cli" "$(gemini --version 2>/dev/null)"
    info "Gemini CLI installed"
fi

# ── Antigravity ──────────────────────────────────────────────────────────────
header "Antigravity"
if command -v antigravity &>/dev/null; then
    info "Antigravity already installed — skipping"
elif confirm "Install Antigravity?"; then
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg \
        | sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" \
        | sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y antigravity
    info "Antigravity installed"
fi

# ── Miniconda + 'tools' env (pkgs/python.libs) ───────────────────────────────
header "Python (Miniconda)"
if [ -d "$HOME/miniconda3" ]; then
    info "Miniconda already installed at ~/miniconda3 — skipping"
    track_detected miniconda "$("$HOME/miniconda3/bin/conda" --version 2>/dev/null | awk '{ print $2 }')"
elif confirm "Install Miniconda?"; then
    wget -q "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p "$HOME/miniconda3"
    rm /tmp/miniconda.sh
    track_install miniconda "curl:Miniconda3-latest" "$("$HOME/miniconda3/bin/conda" --version | awk '{ print $2 }')"

    # 'conda init bash' injects a shell function with an empty if-body when
    # the activate line is commented out, causing a bash syntax error on startup.
    # Write clean initialization instead.
    if ! grep -q "miniconda3/etc/profile.d/conda.sh" "$HOME/.bashrc"; then
        cat >> "$HOME/.bashrc" << 'EOB'

# Conda initialization
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniconda3/etc/profile.d/conda.sh"
fi
EOB
    fi
    info "Miniconda installed. Reload shell: source ~/.bashrc"
fi

CONDA="${HOME}/miniconda3/bin/conda"
CONDA_RUN="env PYTHONNOUSERSITE=1 ${CONDA}"
if ! [ -x "$CONDA" ]; then
    warn "conda not found — skipping 'tools' env"
elif ${CONDA_RUN} env list 2>/dev/null | grep -q "^tools "; then
    info "conda env 'tools' already exists — skipping"
    track_detected conda-env:tools
elif confirm "Create conda env 'tools' (pkgs/python.libs)?"; then
    # conda-forge only: Anaconda's default channels require accepting their ToS
    # (non-interactive runs abort) and a paid license for large organizations
    ${CONDA_RUN} create -y -n tools -c conda-forge --override-channels python
    ${CONDA_RUN} run -n tools pip install -r "${PKGS}/python.libs"
    track_install conda-env:tools "conda-forge + pkgs/python.libs"
    info "conda env 'tools' created"
fi

# radian: modern R console (drop a stale shim first, or pipx refuses to install)
command -v radian &>/dev/null || rm -f "$HOME/.local/bin/radian"
pipx_install radian

# ── fabric (AI augmentation framework) ───────────────────────────────────────
pipx_install fabric

# ── Singularity (HPC containers) ─────────────────────────────────────────────
header "Singularity"
if command -v singularity &>/dev/null; then
    info "Singularity already installed — skipping"
elif confirm "Install Singularity?"; then
    sudo apt-get install -y singularity-container
    info "Singularity $(singularity --version) installed"
fi
