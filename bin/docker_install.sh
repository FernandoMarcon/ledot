#!/bin/bash
# docker_install.sh — install Docker Engine from Docker's official apt repo
# Safe to re-run. Replaces Ubuntu's docker.io stack if present (images/volumes in /var/lib/docker are kept).
# Usage: sudo bash ~/.dotfiles/bin/docker_install.sh

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'
info() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
die()  { echo -e "${RED}[✗]${RESET} $*" >&2; exit 1; }

KEYRING="/etc/apt/keyrings/docker.asc"
SOURCES="/etc/apt/sources.list.d/docker.sources"
CONFLICTS=(docker.io docker-doc docker-compose docker-compose-v2 docker-buildx podman-docker containerd runc)
PKGS=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)

[ "$(id -u)" -eq 0 ] || die "Run with sudo: sudo bash $0"
. /etc/os-release
CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"

export DEBIAN_FRONTEND=noninteractive

# ── 1. Remove conflicting packages ───────────────────────────────────────────
remove_conflicts() {
    local installed=()
    for pkg in "${CONFLICTS[@]}"; do
        dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed" && installed+=("$pkg")
    done
    if [ ${#installed[@]} -eq 0 ]; then
        info "No conflicting packages installed"
        return
    fi
    warn "Removing conflicting packages: ${installed[*]}"
    apt-get remove -y "${installed[@]}"
}

# ── 2. Add Docker apt repo ───────────────────────────────────────────────────
setup_repo() {
    apt-get update -qq
    apt-get install -y ca-certificates curl

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "$KEYRING"
    chmod a+r "$KEYRING"

    # Old one-line repo files (e.g. from older setup scripts) clash on Signed-By
    rm -f /etc/apt/sources.list.d/docker.list

    cat > "$SOURCES" << EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: ${KEYRING}
EOF
    apt-get update -qq
    info "Docker repo configured (${CODENAME})"
}

# ── 3. Install Docker Engine ─────────────────────────────────────────────────
install_docker() {
    apt-get install -y "${PKGS[@]}"
    systemctl enable --now docker containerd
    info "$(docker --version)"
    info "$(docker compose version)"
}

# ── 4. Allow the invoking user to run docker without sudo ────────────────────
setup_group() {
    local user="${SUDO_USER:-}"
    if [ -z "$user" ] || [ "$user" = "root" ]; then
        warn "No non-root user detected — skipping docker group"
        return
    fi
    if id -nG "$user" | grep -qw docker; then
        info "$user already in docker group"
    else
        usermod -aG docker "$user"
        info "Added $user to docker group (log out and back in to apply)"
    fi
}

# ── 5. Smoke test ────────────────────────────────────────────────────────────
smoke_test() {
    if docker run --rm hello-world > /dev/null; then
        info "hello-world container ran successfully"
    else
        warn "hello-world failed — check: systemctl status docker --no-pager"
    fi
}

# ── Run ───────────────────────────────────────────────────────────────────────
remove_conflicts
setup_repo
install_docker
setup_group
smoke_test

echo ""
info "Docker installed. Note: docker group membership is root-equivalent."

# Maintenance cheatsheet:
#   docker restart $(docker ps -aq)      restart all containers
#   docker stop    $(docker ps -aq)      stop all running containers
#   docker rm      $(docker ps -aq)      remove all containers
#   docker rmi     $(docker images -q)   remove all images
#   see also: functions/clean_docker
