#!/bin/bash
# data.sh → where Drive lives on this machine (/data partition, /data/drive dir, mentat over sshfs, or ~/.drive), Syncthing, ~/<dir> links
# Detects the existing layout and reuses it; on a new machine it asks. Layout saved in ~/.local/state/ledot/data-layout
# Usage: bash ~/ledot/setup/data.sh            detect or ask
#        bash ~/ledot/setup/data.sh --choose   ask again (switch layout; contents move to the new place)

set -euo pipefail
SETUP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SETUP}/lib/common.sh"
source "${SETUP}/lib/partition.sh"

DATA_MNT="/data"
DRIVE_DIR="/data/drive"
HOME_DRIVE="${HOME}/.drive"            # home layout: Drive root, not ~ itself (a lost .stignore would sync ~/.ssh)
LAYOUT_FILE="${LEDOT_STATE}/data-layout"
EFI_SCRIPT_DIR="/boot/efi/ledot"
DIRS=(Audio Cursos Data Documents Images Projects Vaults Videos Work dockers utils)
SSHFS_TAG="# ledot: ${HUB_HOST} Drive over sshfs (setup/data.sh)"

if is_work; then
    info "Work profile — no /data, Syncthing or ~ links; skipping"
    exit 0
fi
if is_hub; then
    info "${HUB_HOST} is the hub: /data/drive is the source every machine syncs with — nothing to do"
    exit 0
fi

me() { echo "${USER}:$(id -gn)"; }
saved() { sed -n "s/^$1=//p" "$LAYOUT_FILE" 2>/dev/null; }
save_layout() {
    mkdir -p "$LEDOT_STATE"
    printf 'mode=%s\nroot=%s\n' "$1" "$2" > "$LAYOUT_FILE"
    info "Layout: $1 (Drive at $2)"
}

# ── Mount a /data partition (fstab by UUID, nofail) ──────────────────────────
mount_data_partition() {
    local dev="$1" uuid fstype
    findmnt -n -S "$dev" -o TARGET | grep -qx '/\|/boot\(/efi\)\?' \
        && die "$dev is mounted at / or /boot on this machine — not a data partition"
    uuid=$(sudo blkid -o value -s UUID "$dev")
    fstype=$(sudo blkid -o value -s TYPE "$dev")
    [ -n "$uuid" ] && [ -n "$fstype" ] || die "Could not read UUID/filesystem of $dev"

    move_aside_local_data
    sudo mkdir -p "$DATA_MNT"
    if findmnt --fstab -n "$DATA_MNT" &>/dev/null; then
        info "fstab entry already exists for $DATA_MNT"
    else
        echo "UUID=${uuid}  ${DATA_MNT}  ${fstype}  defaults,nofail  0  2" | sudo tee -a /etc/fstab >/dev/null
        sudo systemctl daemon-reload
        info "fstab: UUID=${uuid} (${fstype}) → $DATA_MNT"
    fi
    mountpoint -q "$DATA_MNT" || sudo mount "$DATA_MNT"
    info "$dev mounted at $DATA_MNT"
    sudo chown "$(me)" "$DATA_MNT"
    restore_local_data
}

# A /data/drive dir on / (dir layout) would be hidden by a mount on /data: move it aside, copy it back after
move_aside_local_data() {
    OLD_DATA=""
    if [ -d "$DATA_MNT" ] && ! mountpoint -q "$DATA_MNT" && [ -n "$(ls -A "$DATA_MNT" 2>/dev/null)" ]; then
        OLD_DATA="${DATA_MNT}.pre-mount-$(date +%Y%m%d%H%M%S)"
        sudo mv "$DATA_MNT" "$OLD_DATA"
        warn "Moved the existing $DATA_MNT (on /) to $OLD_DATA"
    fi
}
restore_local_data() {
    [ -n "${OLD_DATA:-}" ] || return 0
    info "Copying $OLD_DATA → $DATA_MNT ..."
    sudo rsync -aHAX "${OLD_DATA}/" "${DATA_MNT}/"
    if confirm "Copied. Delete $OLD_DATA (frees space on /)?"; then sudo rm -rf "$OLD_DATA"; fi
}

# ── Layouts ──────────────────────────────────────────────────────────────────
layout_partition() {   # $1: existing block device, or empty to create one from the plan
    local dev="${1:-}"
    remove_sshfs
    if [ -z "$dev" ]; then
        info "Creating /data: $(plan_summary)"
        dev=$(create_data_online)
        info "Created $dev (ext4, label data)"
    fi
    mount_data_partition "$dev"
    sudo install -d -o "$USER" -g "$(id -gn)" -m 755 "$DRIVE_DIR"
    save_layout partition "$DRIVE_DIR"
}

layout_dir() {
    remove_sshfs
    # /data and /data/drive owned by you, so day-to-day files never need sudo
    sudo install -d -o "$USER" -g "$(id -gn)" -m 755 "$DATA_MNT" "$DRIVE_DIR"
    info "$DRIVE_DIR ready on / (owner $(me))"
    save_layout dir "$DRIVE_DIR"
}

layout_home() {
    remove_sshfs
    mkdir -p "$HOME_DRIVE"
    info "$HOME_DRIVE ready"
    save_layout home "$HOME_DRIVE"
}

layout_sshfs() {
    ensure_hub_ssh || die "sshfs needs passwordless ssh to ${HUB_HOST}"
    command -v sshfs &>/dev/null || sudo apt-get install -y sshfs
    local host user
    host=$(ssh -G "$HUB_HOST" | awk '$1 == "hostname" { print $2 }')
    user=$(ssh -G "$HUB_HOST" | awk '$1 == "user" { print $2 }')

    sudo install -d -o "$USER" -g "$(id -gn)" -m 755 "$DATA_MNT"
    if [ -d "$DRIVE_DIR" ] && ! mountpoint -q "$DRIVE_DIR" && [ -n "$(ls -A "$DRIVE_DIR")" ]; then
        local aside; aside="${DRIVE_DIR}.local-$(date +%Y%m%d%H%M%S)"
        mv "$DRIVE_DIR" "$aside"
        warn "$DRIVE_DIR wasn't empty — moved to $aside (copy anything you need onto the mount)"
    fi
    mkdir -p "$DRIVE_DIR"

    if grep -qxF "$SSHFS_TAG" /etc/fstab; then
        info "fstab: sshfs entry already present"
    else
        # Mounted by root at boot (automount on first access) with your key and known_hosts; files show as yours
        printf '%s\n%s@%s:%s  %s  fuse.sshfs  %s  0  0\n' "$SSHFS_TAG" "$user" "$host" "$HUB_DRIVE" "$DRIVE_DIR" \
            "noauto,x-systemd.automount,x-systemd.mount-timeout=30,_netdev,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,IdentityFile=${SSH_KEY},UserKnownHostsFile=${HOME}/.ssh/known_hosts,allow_other,uid=$(id -u),gid=$(id -g)" \
            | sudo tee -a /etc/fstab >/dev/null
        info "fstab: ${user}@${host}:${HUB_DRIVE} → $DRIVE_DIR (sshfs, automount)"
    fi
    sudo systemctl daemon-reload
    sudo systemctl restart "$(systemd-escape -p --suffix=automount "$DRIVE_DIR")"
    ls "$DRIVE_DIR" >/dev/null 2>&1 && mountpoint -q "$DRIVE_DIR" \
        || die "sshfs mount failed — try: sudo mount $DRIVE_DIR; journalctl -u $(systemd-escape -p --suffix=mount "$DRIVE_DIR")"
    info "${HUB_HOST}:${HUB_DRIVE} mounted at $DRIVE_DIR"

    # Syncthing would sync the hub with itself through the mount
    docker ps --format '{{.Names}}' 2>/dev/null | grep -qx syncthing \
        && { docker stop syncthing >/dev/null; docker update --restart=no syncthing >/dev/null; warn "Stopped the local Syncthing container (not needed with sshfs)"; }
    save_layout sshfs "$DRIVE_DIR"
}

remove_sshfs() {
    grep -qxF "$SSHFS_TAG" /etc/fstab 2>/dev/null || return 0
    mountpoint -q "$DRIVE_DIR" && sudo umount "$DRIVE_DIR"
    sudo systemctl stop "$(systemd-escape -p --suffix=automount "$DRIVE_DIR")" 2>/dev/null || true
    sudo sed -i "\\|^${SSHFS_TAG}\$|{N;d}" /etc/fstab
    sudo systemctl daemon-reload
    info "Removed the sshfs mount of ${HUB_HOST}'s Drive"
}

# ── ~/<dir> → <root>/<dir> ───────────────────────────────────────────────────
link_dirs() {
    local root="$1" name home_path target old
    for name in "${DIRS[@]}"; do
        home_path="${HOME}/${name}"
        target="${root}/${name}"
        mkdir -p "$target"

        if [ -L "$home_path" ]; then
            old=$(readlink "$home_path")
            if [ "$(readlink -f "$home_path")" = "$(readlink -f "$target")" ]; then
                info "Already linked: ~/${name} → $target"; continue
            fi
            # Linked to another Drive root (layout switch): move what's there, then relink
            if [ "$old" = "${DRIVE_DIR}/${name}" ] || [ "$old" = "${HOME_DRIVE}/${name}" ]; then
                if [ -d "$old" ] && [ -n "$(ls -A "$old" 2>/dev/null)" ] && ! mountpoint -q "$(dirname "$old")"; then
                    info "Moving $old → $target"
                    rsync -a --remove-source-files "${old}/" "${target}/" && find "$old" -type d -empty -delete
                fi
                rm "$home_path"
            else
                warn "Skipping ~/${name} — symlink to $old (not a Drive root)"; continue
            fi
        elif [ -d "$home_path" ]; then
            # Real directory — move its contents in, then replace it with the link
            if [ -n "$(ls -A "$home_path" 2>/dev/null)" ]; then
                info "Migrating ~/${name} → $target"
                cp -a "${home_path}/." "${target}/"
            fi
            rm -rf "$home_path"
        fi
        ln -s "$target" "$home_path"
        info "Linked: ~/${name} → $target"
    done
    mkdir -p "${root}/Projects/homelab"   # homelab lives inside Projects
}

# ── Detection ────────────────────────────────────────────────────────────────
# Unmounted ext4 partitions labelled "data" (fs label or GPT name): a reinstall keeps /data
# (lsblk -r keeps empty columns as empty fields when split on single spaces)
labelled_data_partition() {
    lsblk -rnpo NAME,TYPE,FSTYPE,LABEL,PARTLABEL,MOUNTPOINT \
        | awk -F'[ ]' '$2 ~ /^(part|lvm)$/ && $3 == "ext4" && ($4 == "data" || $5 == "data") && $6 == "" { print $1; exit }'
}
# Other unmounted ext4 partitions ≥ DATA_MIN_GIB (could also be a UPS reserve — the menu says so)
other_big_partitions() {
    lsblk -rnbpo NAME,TYPE,FSTYPE,SIZE,MOUNTPOINT \
        | awk -F'[ ]' -v min=$(( DATA_MIN_GIB * GIB )) '$2 == "part" && $3 == "ext4" && $4 >= min && $5 == "" { print $1 }'
}

has_battery() { compgen -G "/sys/class/power_supply/BAT*" >/dev/null; }

hub_drive_bytes() {   # size of mentat's Drive, or empty when unreachable
    has_hub_ssh_entry && hub_ssh "du -sb ${HUB_DRIVE} 2>/dev/null | cut -f1" 2>/dev/null || true
}

# ── Choose a layout (new machine, or --choose) ───────────────────────────────
choose_layout() {
    header "Where should Drive live on $(hostname)?"
    command -v parted &>/dev/null || sudo apt-get install -y parted
    plan_layout
    local hub_bytes free_root
    hub_bytes=$(hub_drive_bytes)
    free_root=$(df -B1 --output=avail / | tail -1 | tr -d ' ')

    echo "  Disk:   ${P_DISK:-?} $(gib_str "${P_DISK_BYTES:-0}") · / $(gib_str "$P_ROOT_USED") used of $(gib_str "$P_ROOT_BYTES") (${P_KIND}) · free on /: $(gib_str "$free_root")"
    if [ -n "$hub_bytes" ]; then
        echo "  ${HUB_HOST}: Drive is $(gib_str "$hub_bytes") — a full local copy needs that much space"
    else
        echo "  ${HUB_HOST}: not reachable over ssh yet (set up when needed)"
    fi
    has_battery && echo "  Battery present — treating this as a laptop (sshfs mount not recommended)"
    echo ""

    # Recommendation: repartition when it can be done now; else sshfs for a small-disk desktop; else /data/drive dir
    local rec=2 small=0
    [ -n "$hub_bytes" ] && [ "$free_root" -lt $(( hub_bytes * 11 / 10 )) ] && small=1
    [ "$P_MODE" = none ] && [ "${P_DISK_BYTES:-0}" -lt $(( (ROOT_FLOOR_GIB + DATA_MIN_GIB) * GIB )) ] && small=1
    if [ "$P_MODE" = online ]; then rec=1
    elif [ "$small" -eq 1 ] && ! has_battery; then rec=3
    elif [ "$P_MODE" = offline ]; then rec=1
    fi

    local -a opt=()
    case "$P_MODE" in
        online)  opt[1]="Repartition: / | UPS | /data  → $(plan_summary) (now, from free space)" ;;
        offline) opt[1]="Repartition: / | UPS | /data  → $(plan_summary) (live USB: ${P_WHY})" ;;
        none)    opt[1]="Repartition: unavailable — ${P_WHY}" ;;
    esac
    opt[2]="/data/drive folder on /          → Syncthing ⇄ ${HUB_HOST}, ~/<dir> links (no repartition)"
    opt[3]="Mount ${HUB_HOST}:/data/drive (sshfs) → no local copy, no Syncthing; stationary LAN machines only"
    opt[4]="Dirs in home (~/.drive)          → Syncthing ⇄ ${HUB_HOST}, ~/<dir> links (last resort)"
    local existing="" i
    existing=$(other_big_partitions | head -1)
    [ -n "$existing" ] && opt[5]="Use existing partition $existing ($(lsblk -dno SIZE "$existing" | tr -d ' ')) as /data — make sure it isn't a UPS reserve"

    for i in "${!opt[@]}"; do
        if [ "$i" -eq "$rec" ]; then echo -e "  ${i}) ${opt[$i]}  ${GREEN}[recommended]${RESET}"
        else echo "  ${i}) ${opt[$i]}"; fi
    done
    echo "  s) skip for now"
    local ans
    read -rp "$(echo -e "${YELLOW}[?]${RESET} Choice [${rec}]: ")" ans
    ans="${ans:-$rec}"

    case "$ans" in
        1)
            [ "$P_MODE" = none ] && die "Repartition unavailable: ${P_WHY}"
            local size
            read -rp "     /data size in GiB [$(( P_DATA_BYTES / GIB ))] (min ${DATA_MIN_GIB}, UPS gets the rest): " size
            if [ -n "$size" ]; then
                [[ "$size" =~ ^[0-9]+$ ]] && set_data_size "$size" || die "Invalid size: $size"
            fi
            info "Plan: $(plan_summary)"
            if [ "$P_MODE" = online ]; then
                confirm "Create /data now (${P_DISK}, no reboot)?" || die "Aborted"
                layout_partition ""
                return
            fi
            local script="${EFI_SCRIPT_DIR}/repartition.sh"
            mountpoint -q /boot/efi || script="${HOME}/ledot-repartition-$(hostname).sh"
            sudo mkdir -p "$(dirname "$script")"
            write_offline_script "$script"
            info "Live-USB script written: $script"
            note "Boot a live USB and run it (steps at the top of the script), then: install.sh data"
            sed -n '2,6p' "$script" | sed 's/^#/   /'
            confirm_no "Use a temporary layout until then (Drive moves to /data after the repartition)?" || exit 0
            choose_temporary
            ;;
        2) layout_dir ;;
        3)
            if has_battery && ! confirm_no "This looks like a laptop — sshfs needs ${HUB_HOST} reachable. Continue?"; then exit 0; fi
            layout_sshfs ;;
        4) layout_home ;;
        5)
            [ -n "$existing" ] || die "Invalid choice: 5"
            confirm "Mount $existing at /data as is (nothing is formatted)?" || exit 0
            layout_partition "$existing" ;;
        s|S) warn "Skipped — run install.sh data later"; exit 0 ;;
        *) die "Invalid choice: $ans" ;;
    esac
}

choose_temporary() {
    local ans
    read -rp "     Temporary layout: 2) /data/drive on /  3) sshfs mount  4) ~/.drive  [2]: " ans
    case "${ans:-2}" in 2) layout_dir ;; 3) layout_sshfs ;; 4) layout_home ;; *) die "Invalid choice" ;; esac
}

# ── Run ──────────────────────────────────────────────────────────────────────
mode="$(saved mode)"
dev=""
if [ "${1:-}" = "--choose" ]; then
    choose_layout
elif mountpoint -q "$DATA_MNT"; then
    info "$DATA_MNT already mounted ($(findmnt -no SOURCE "$DATA_MNT"))"
    findmnt --fstab -n "$DATA_MNT" &>/dev/null || mount_data_partition "$(findmnt -no SOURCE "$DATA_MNT")"
    sudo install -d -o "$USER" -g "$(id -gn)" -m 755 "$DRIVE_DIR"
    save_layout partition "$DRIVE_DIR"
elif findmnt --fstab -n "$DATA_MNT" &>/dev/null; then
    info "Mounting $DATA_MNT from fstab..."
    sudo mount "$DATA_MNT"
    sudo install -d -o "$USER" -g "$(id -gn)" -m 755 "$DRIVE_DIR"
    save_layout partition "$DRIVE_DIR"
elif dev=$(labelled_data_partition) && [ -n "$dev" ]; then
    info "Found a data partition: $dev ($(lsblk -dno SIZE "$dev" | tr -d ' '))"
    confirm "Mount $dev at $DATA_MNT${mode:+ (replaces the '${mode}' layout)}?" || exit 0
    layout_partition "$dev"
elif [ -n "$mode" ]; then
    info "Saved layout: $mode"
    case "$mode" in
        dir) layout_dir ;; home) layout_home ;; sshfs) layout_sshfs ;;
        partition) die "Saved layout is a /data partition, but none is mounted or in fstab — bash ~/ledot/setup/data.sh --choose" ;;
    esac
else
    choose_layout
fi

ROOT="$(saved root)"
header "Links: ~/<dir> → ${ROOT}/<dir>"
link_dirs "$ROOT"

if [ "$(saved mode)" != sshfs ]; then
    header "Syncthing"
    bash "${SETUP}/syncthing.sh" "$ROOT"
fi
