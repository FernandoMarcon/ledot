#!/bin/bash
# elegoo.sh → ElegooSlicer (3D printing slicer): release AppImage from GitHub, or --source to build it
# Usage: bash ~/ledot/setup/elegoo.sh [--source [tarball]]
#   default   latest release AppImage → ~/.local/share/elegoo-slicer, `elegoo-slicer` launcher + menu entry
#   --source  build the AppImage from source (tarball arg, else ~/Downloads/ElegooSlicer-<ver>.tar.gz,
#             else download it), patched for Ubuntu 26.04 — takes hours; see docs/printers/elegoo-slicer.md

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

REPO="ELEGOO-3D/ElegooSlicer"
APP_DIR="${HOME}/.local/share/elegoo-slicer"
APPIMAGE="${APP_DIR}/ElegooSlicer.AppImage"
# Source tree path must not contain ".3": curl's docs build rewrites ".3" → ".md" across the whole path
SRC_DIR="${HOME}/src/elegoo-slicer"

MODE="appimage"
TARBALL=""
case "${1:-}" in
    --source) MODE="source"; TARBALL="${2:-}" ;;
    "") ;;
    *) die "Unknown option: $1 (usage: elegoo.sh [--source [tarball]])" ;;
esac

install_list elegoo

# The app switches its UI to en_US and fails ("Switching language failed") if that locale isn't generated
if ! locale -a | grep -qi '^en_US\.utf-\?8$'; then
    sudo locale-gen en_US.UTF-8
    info "en_US.UTF-8 locale generated"
fi

TAG=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
[ -n "$TAG" ] || die "Could not get the latest ${REPO} release"
VERSION="${TAG#v}"

INSTALLED=$(awk -F'\t' '$1 == "elegoo-slicer" { print $3 }' "$INSTALL_STATE" 2>/dev/null || true)
if [ -x "$APPIMAGE" ] && [ "$INSTALLED" == "$VERSION" ]; then
    info "ElegooSlicer ${VERSION} already installed — skipping"
    exit 0
fi

mkdir -p "$APP_DIR" ~/.local/bin ~/.local/share/applications

if [ "$MODE" == "appimage" ]; then
    URL="https://github.com/${REPO}/releases/download/${TAG}/ElegooSlicer_Linux_V${VERSION}.AppImage"
    info "Downloading ElegooSlicer ${VERSION} AppImage..."
    curl -fL "$URL" -o "${APPIMAGE}.part"
    mv "${APPIMAGE}.part" "$APPIMAGE"
    SOURCE="github:${TAG}"
else
    # ── Source ───────────────────────────────────────────────────────────────
    [ -n "$TARBALL" ] || TARBALL="${HOME}/Downloads/ElegooSlicer-${VERSION}.tar.gz"
    if [ ! -f "$TARBALL" ]; then
        info "Downloading ElegooSlicer ${VERSION} source..."
        TARBALL="$(mktemp -d)/ElegooSlicer-${VERSION}.tar.gz"
        curl -fL "https://github.com/${REPO}/archive/refs/tags/${TAG}.tar.gz" -o "$TARBALL"
    fi
    if [ -d "$SRC_DIR" ]; then
        confirm "Replace the existing source tree ${SRC_DIR}?" || die "Aborted"
        rm -rf "$SRC_DIR"
    fi
    mkdir -p "$SRC_DIR"
    tar -C "$SRC_DIR" --strip-components=1 -xzf "$TARBALL"
    cd "$SRC_DIR"

    # Fixes (all idempotent):
    # 1. curl 8.14 docs build turns ".3" into ".md" anywhere in the path → don't build curl docs
    grep -q BUILD_LIBCURL_DOCS deps/CURL/CURL.cmake || sed -i \
        's/^\( *\)-DBUILD_CURL_EXE:BOOL=OFF/&\n\1-DBUILD_LIBCURL_DOCS:BOOL=OFF\n\1-DBUILD_MISC_DOCS:BOOL=OFF\n\1-DENABLE_CURL_MANUAL:BOOL=OFF/' \
        deps/CURL/CURL.cmake
    # 2. RAM check rejected exactly the 10G minimum
    sed -i 's/\${FREE_MEM_GB} -le \${MIN_MEM_GB}/${FREE_MEM_GB} -lt ${MIN_MEM_GB}/' build_linux.sh
    # 3. GCC 15 no longer includes <algorithm> transitively; elegoolink (cloned from git main) relies on it
    grep -q 'include algorithm' deps/elegoolink/elegoolink.cmake || sed -i \
        's/^\( *\)-DELEGOO_INTERNAL_TESTING=\${ELEGOO_INTERNAL_TESTING}/&\n\1"-DCMAKE_CXX_FLAGS:STRING=-include algorithm"/' \
        deps/elegoolink/elegoolink.cmake

    info "Installing build dependencies..."
    sudo ./build_linux.sh -u
    info "Building ElegooSlicer ${VERSION} (deps + app + AppImage; this takes hours)..."
    # -j2: 4 parallel GUI compiles can exhaust 14G RAM; not as root: a sudo build leaves root-owned files in the tree
    ./build_linux.sh -j2 -dsi

    BUILT=$(find build -maxdepth 2 -name "ElegooSlicer_Linux_V*.AppImage" | head -1)
    [ -n "$BUILT" ] || die "Build finished but no AppImage found under ${SRC_DIR}/build"
    cp "$BUILT" "$APPIMAGE"
    SOURCE="source:${TAG}"
fi

chmod +x "$APPIMAGE"
ln -sf "$APPIMAGE" ~/.local/bin/elegoo-slicer

# ── Menu entry ───────────────────────────────────────────────────────────────
TMP=$(mktemp -d)
ICON="${APP_DIR}/ElegooSlicer.png"
( cd "$TMP" && "$APPIMAGE" --appimage-extract ElegooSlicer.png >/dev/null 2>&1 ) \
    && cp -L "${TMP}/squashfs-root/ElegooSlicer.png" "$ICON" || ICON="applications-graphics"
rm -rf "$TMP"
cat > ~/.local/share/applications/elegoo-slicer.desktop <<EOF
[Desktop Entry]
Name=ElegooSlicer
Comment=3D printing slicer
Exec=${APPIMAGE} %F
Icon=${ICON}
Terminal=false
Type=Application
Categories=Graphics;3DGraphics;Engineering;
MimeType=model/stl;model/3mf;application/vnd.ms-3mfdocument;model/obj;application/x-amf;
EOF
update-desktop-database ~/.local/share/applications 2>/dev/null || true

track_install elegoo-slicer "$SOURCE" "$VERSION"
info "ElegooSlicer ${VERSION} installed — run: elegoo-slicer"
