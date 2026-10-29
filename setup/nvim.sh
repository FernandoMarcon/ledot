#!/bin/bash
# nvim.sh → setup nvim
# Usage: bash ~/ledot/setup/nvim.sh

set -eou pipefail
# source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

echo -e "\t[ NVIM ] Create local bin directory"
echo -e "\t $ mkdir -p ~/.local/bin ~/.local/share"
mkdir -p ~/.local/bin ~/.local/share

echo -e "\t[ NVIM ] Download and extract the latest stable Neovim tarball"
echo -e "\t $ curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
echo -e "\t $ tar -C ~/.local/share -xzf nvim-linux-x86_64.tar.gz"
tar -C ~/.local/share -xzf nvim-linux-x86_64.tar.gz

echo -e "\t[ NVIM ] Create a symlink in your local bin path"
echo -e "\t $ ln -sf ~/.local/share/nvim-linux-x86_64/bin/nvim ~/.local/bin/nvim"
ln -sf ~/.local/share/nvim-linux-x86_64/bin/nvim ~/.local/bin/nvim
