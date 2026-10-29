#!/bin/bash
# nvim.sh → setup nvim; source preference: 1. progs/ tarball, 2. latest GitHub release, 3. apt
# Usage: bash ~/ledot/setup/nvim.sh

set -eou pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

TARBALL="${DOTFILES}/progs/nvim-linux-x86_64.tar.gz"
RELEASE_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"

if [ -f "${TARBALL}" ]; then
    echo -e "\t[ NVIM ] Using the Neovim tarball from the repo (${TARBALL})"
    SOURCE="repo:progs/nvim-linux-x86_64.tar.gz"
else
    echo -e "\t[ NVIM ] Tarball not found in repo — downloading the latest stable release"
    SOURCE="github:latest"
    TARBALL="$(mktemp -d)/nvim-linux-x86_64.tar.gz"
    echo -e "\t $ curl -fL ${RELEASE_URL} -o ${TARBALL}"
    if ! curl -fL "${RELEASE_URL}" -o "${TARBALL}"; then
        echo -e "\t[ NVIM ] Download failed — installing from apt"
        echo -e "\t $ sudo apt-get install -y neovim"
        sudo apt-get install -y neovim
        track_install nvim apt "$(nvim --version | awk 'NR == 1 { print $2 }')"
        exit 0
    fi
fi

echo -e "\t[ NVIM ] Create local bin directory"
echo -e "\t $ mkdir -p ~/.local/bin ~/.local/share"
mkdir -p ~/.local/bin ~/.local/share

echo -e "\t[ NVIM ] Extract the Neovim tarball"
echo -e "\t $ tar -C ~/.local/share -xzf ${TARBALL}"
tar -C ~/.local/share -xzf "${TARBALL}"

echo -e "\t[ NVIM ] Create a symlink in your local bin path"
echo -e "\t $ ln -sf ~/.local/share/nvim-linux-x86_64/bin/nvim ~/.local/bin/nvim"
ln -sf ~/.local/share/nvim-linux-x86_64/bin/nvim ~/.local/bin/nvim

track_install nvim "${SOURCE}" "$(~/.local/bin/nvim --version | awk 'NR == 1 { print $2 }')"
