#!/usr/bin/env bash
## Module 09 – GUI applications
## Thunar (file manager), Geany (editor), Firefox (browser),
## Viewnior (image viewer), YAD (dialog tool).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

log_section "GUI Applications"

apt_install \
    thunar \
    thunar-archive-plugin \
    thunar-volman \
    geany \
    geany-plugins \
    firefox \
    viewnior \
    yad \
    file-roller \
    tumbler

log_ok "GUI applications installed"
