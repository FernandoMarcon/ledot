#!/usr/bin/env bash

## Copyright (C) 2020-2024 Aditya Shakya <adi1090x@gmail.com>

set -o noclobber -o noglob -o nounset -o pipefail
IFS=$'\n'

# If the option `use_preview_script` is set to `true`,
# then this script will be called and its output will be displayed in ranger.
# ANSI color codes are supported.
# STDIN is disabled, so interactive scripts won't work properly

# This script is considered a configuration file and must be updated manually.
# It will be left untouched if you upgrade ranger.

# Meanings of exit codes:
# code | meaning    | action of ranger
# -----+------------+-------------------------------------------
# 0    | success    | Display stdout as preview
# 1    | no preview | Display no preview at all
# 2    | plain text | Display the plain content of the file
# 3    | fix width  | Don't reload when width changes
# 4    | fix height | Don't reload when height changes
# 5    | fix both   | Don't ever reload
# 6    | image      | Display the image `$IMAGE_CACHE_PATH` points to as an image preview
# 7    | image      | Display the file directly as an image

# Script arguments
FILE_PATH="${1}"         # Full path of the highlighted file
PV_WIDTH="${2}"          # Width of the preview pane (number of fitting characters)
PV_HEIGHT="${3}"         # Height of the preview pane (number of fitting characters)
IMAGE_CACHE_PATH="${4}"  # Full path that should be used to cache image preview
PV_IMAGE_ENABLED="${5}"  # 'True' if image previews are enabled, 'False' otherwise.

FILE_EXTENSION="${FILE_PATH##*.}"
FILE_EXTENSION_LOWER=$(echo ${FILE_EXTENSION} | tr '[:upper:]' '[:lower:]')

# Settings
HIGHLIGHT_SIZE_MAX=262143  # 256KiB
HIGHLIGHT_TABWIDTH=8
HIGHLIGHT_STYLE='pablo'
PYGMENTIZE_STYLE='autumn'


handle_extension() {
    case "${FILE_EXTENSION_LOWER}" in
        # Archive
        a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|\
        rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)
            atool --list -- "${FILE_PATH}" && exit 5
            bsdtar --list --file "${FILE_PATH}" && exit 5
            exit 1;;
        rar)
            # Avoid password prompt by providing empty password
            unrar lt -p- -- "${FILE_PATH}" && exit 5
            exit 1;;
        7z)
            # Avoid password prompt by providing empty password
            7z l -p -- "${FILE_PATH}" && exit 5
            exit 1;;

        # PDF
        pdf)
            # Preview as text conversion
            pdftotext -l 10 -nopgbrk -q -- "${FILE_PATH}" - && exit 5
            exiftool "${FILE_PATH}" && exit 5
            exit 1;;

        # BitTorrent
        torrent)
            transmission-show -- "${FILE_PATH}" && exit 5
            exit 1;;

        # OpenDocument
        odt|ods|odp|sxw)
            # Preview as text conversion
            odt2txt "${FILE_PATH}" && exit 5
            exit 1;;

        # HTML
        htm|html|xhtml)
            # Preview as text conversion
            w3m -dump "${FILE_PATH}" && exit 5
            # xdg-open "${FILE_PATH}" && exit 5
            lynx -dump -- "${FILE_PATH}" && exit 5
            elinks -dump "${FILE_PATH}" && exit 5
            ;; # Continue with next handler on failure
    esac
}

# Show the image just written to IMAGE_CACHE_PATH: as a real image when ranger
# draws images, else (e.g. inside tmux) as chafa text art
show_cached_image() {
    [[ -s "${IMAGE_CACHE_PATH}" ]] || return 1
    [[ "${PV_IMAGE_ENABLED}" == 'True' ]] && exit 6
    chafa --format=symbols --colors=256 --animate=off --size="${PV_WIDTH}x${PV_HEIGHT}" \
        -- "${IMAGE_CACHE_PATH}" && exit 4
    return 1
}

# Files that are previewed by rendering them to an image first
handle_render() {
    case "${FILE_EXTENSION_LOWER}" in
        # 3MF (zip, detected as octet-stream): embedded slicer thumbnail
        3mf)
            local thumb
            for thumb in Auxiliaries/.thumbnails/thumbnail_middle.png \
                         Auxiliaries/.thumbnails/thumbnail_3mf.png \
                         Metadata/plate_1.png Metadata/thumbnail.png; do
                unzip -p -- "${FILE_PATH}" "${thumb}" >| "${IMAGE_CACHE_PATH}" 2>/dev/null \
                    && show_cached_image
            done
            exit 1;;

        # PDF: first page
        pdf)
            pdftoppm -f 1 -l 1 -scale-to-x 1920 -scale-to-y -1 -singlefile \
                     -jpeg -- "${FILE_PATH}" "${IMAGE_CACHE_PATH%.*}" 2>/dev/null \
                && show_cached_image
            pdftotext -l 3 -layout -- "${FILE_PATH}" - 2>/dev/null && exit 5
            exit 1;;

        # CAD / meshes: render with f3d (OpenCascade build reads STEP)
        step|stp|stl|obj)
            if command -v f3d >/dev/null; then
                # 3/4 view; OBJ is usually Y-up, STL/STEP Z-up
                local png="${IMAGE_CACHE_PATH%.*}.png" up=+Z dir=-1,1,-0.8
                [[ "${FILE_EXTENSION_LOWER}" == obj ]] && up=+Y dir=-1,-0.8,-1
                timeout 15 f3d --no-config --output="${png}" --resolution=800,600 \
                        --up="${up}" --camera-direction="${dir}" \
                        --filename=false --grid=false -- "${FILE_PATH}" >/dev/null 2>&1 \
                    && mv -f -- "${png}" "${IMAGE_CACHE_PATH}" && show_cached_image
            fi
            # STEP is plain text: show its header (file name, author, products)
            if [[ "${FILE_EXTENSION_LOWER}" == st[ep]* ]]; then
                grep -m 20 -E "FILE_NAME|FILE_DESCRIPTION|PRODUCT\(" -- "${FILE_PATH}" && exit 5
            fi
            return;;
    esac
}

handle_image() {
    local mimetype="${1}"
    case "${mimetype}" in
        # SVG
        image/svg+xml)
             convert "${FILE_PATH}" "${IMAGE_CACHE_PATH}" && exit 6
             exit 1;;

        # Image
        image/*)
            local orientation
            orientation="$( identify -format '%[EXIF:Orientation]\n' -- "${FILE_PATH}" )"
            # If orientation data is present and the image actually
            # needs rotating ("1" means no rotation)...
            if [[ -n "$orientation" && "$orientation" != 1 ]]; then
                # ...auto-rotate the image according to the EXIF data.
                convert -- "${FILE_PATH}" -auto-orient "${IMAGE_CACHE_PATH}" && exit 6
            fi

            # `w3mimgdisplay` will be called for all images (unless overriden as above),
            # but might fail for unsupported types.
            exit 7;;

        # Video
        video/*)
             # Thumbnail
             ffmpegthumbnailer -i "${FILE_PATH}" -o "${IMAGE_CACHE_PATH}" -s 0 && exit 6
             exit 1;;
        
    esac
}

handle_mime() {
    local mimetype="${1}"
    case "${mimetype}" in
        # Text
        text/* | */xml)
            # Syntax highlight
            if [[ "$( stat --printf='%s' -- "${FILE_PATH}" )" -gt "${HIGHLIGHT_SIZE_MAX}" ]]; then
                exit 2
            fi
            if [[ "$( tput colors )" -ge 256 ]]; then
                local pygmentize_format='terminal256'
                local highlight_format='xterm256'
            else
                local pygmentize_format='terminal'
                local highlight_format='ansi'
            fi
            highlight --replace-tabs="${HIGHLIGHT_TABWIDTH}" --out-format="${highlight_format}" \
                --style="${HIGHLIGHT_STYLE}" --force -- "${FILE_PATH}" && exit 5
            # pygmentize -f "${pygmentize_format}" -O "style=${PYGMENTIZE_STYLE}" -- "${FILE_PATH}" && exit 5
            exit 2;;

        # Image
        image/*)
            # Preview as text conversion
            # img2txt --gamma=0.6 --width="${PV_WIDTH}" -- "${FILE_PATH}" && exit 4
            chafa --format=symbols --colors=256 --animate=off --size="${PV_WIDTH}x${PV_HEIGHT}" \
                -- "${FILE_PATH}" && exit 4
            exiftool "${FILE_PATH}" && exit 5
            exit 1;;

        # Video and audio
        video/* | audio/*)
            mediainfo "${FILE_PATH}" && exit 5
            exiftool "${FILE_PATH}" && exit 5
            exit 1;;
    esac
}

handle_fallback() {
    echo '----- File Type Classification -----' && file --dereference --brief -- "${FILE_PATH}" && exit 5
    exit 1
}


MIMETYPE="$( file --dereference --brief --mime-type -- "${FILE_PATH}" )"
handle_render
if [[ "${PV_IMAGE_ENABLED}" == 'True' ]]; then
    handle_image "${MIMETYPE}"
fi
handle_extension
handle_mime "${MIMETYPE}"
handle_fallback

exit 1
