#!/bin/bash
# r.sh → R packages from pkgs/r.libs (+ build deps in pkgs/r-build.list); asks, default no
# Run after: dev (r-base). install.sh runs it last — it is slow
# Usage: bash ~/ledot/setup/r.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

header "R"
if ! command -v Rscript &>/dev/null; then
    warn "Rscript not found — r-base (dev.list) failed to install"
elif confirm_no "Install R packages from r.libs?"; then
    # tidyverse and its deps (ragg, httr, rvest, reprex, etc.) require system libs
    install_list r-build
    Rscript -e "
        userlib <- Sys.getenv('R_LIBS_USER', unset = path.expand('~/R/library'))
        dir.create(userlib, recursive = TRUE, showWarnings = FALSE)
        .libPaths(c(userlib, .libPaths()))
        pkgs <- readLines('${PKGS}/r.libs')
        pkgs <- pkgs[nzchar(pkgs) & !startsWith(pkgs, '#')]
        new  <- pkgs[!pkgs %in% installed.packages()[, 'Package']]
        if (length(new)) install.packages(new, repos='https://cloud.r-project.org', lib = userlib, dependencies = TRUE) else message('all packages already installed')
    "
    info "R packages installed"
fi
