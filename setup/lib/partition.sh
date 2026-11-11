# partition.sh — disk planning for data.sh (source it, don't run it)
# shellcheck shell=bash disable=SC2034  # sourced by data.sh, which uses the P_* results
# Target layout:  /  |  UPS (unallocated reserve, grows either neighbour)  |  /data
#   /      used × (1 + ROOT_HEADROOM_PCT %), rounded up to ROOT_ROUND_GIB, at least ROOT_FLOOR_GIB
#   /data  500 GiB if it fits, else 400, else 250 (minimum); can be changed at the prompt
#   UPS    whatever is left
# Online (no reboot) when the space already exists: unpartitioned disk space, or free extents in root's LVM VG.
# Otherwise / must shrink, which ext4 only does unmounted: write a script to run from a live USB.

GIB=$((1024 ** 3))
MIB=$((1024 ** 2))
ROOT_HEADROOM_PCT=20
ROOT_ROUND_GIB=5
ROOT_FLOOR_GIB=20
DATA_MIN_GIB=250
DATA_GOOD_GIB=400
DATA_IDEAL_GIB=500

to_gib()  { echo $(( ($1 + GIB - 1) / GIB )); }          # bytes → GiB, rounded up
gib_str() { awk -v b="$1" 'BEGIN { printf "%.0f GiB", b / 1073741824 }'; }

# Filled by plan_layout
P_KIND=""        # part | lvm | unsupported
P_WHY=""         # why unsupported / why offline
P_ROOT_DEV=""    # /dev/sda2 or /dev/mapper/vg-lv
P_DISK=""        # /dev/sda
P_DISK_BYTES=0
P_ROOT_BYTES=0
P_ROOT_USED=0
P_ROOT_TARGET=0  # bytes / should have after the plan (= current size when online)
P_VG=""; P_LV=""
P_FREE_START=0; P_FREE_END=0; P_FREE_BYTES=0   # largest unpartitioned region, or VG free (lvm)
P_MODE=""        # online | offline | none
P_DATA_BYTES=0
P_UPS_BYTES=0

# largest_free_region <disk> — "start end size" (bytes, end inclusive) of the biggest unpartitioned gap
largest_free_region() {
    sudo parted -m -s "$1" unit B print free 2>/dev/null \
        | awk -F: '$5 == "free;" { s = $2; e = $3; z = $4; gsub("B", "", s); gsub("B", "", e); gsub("B", "", z)
                                   if (z + 0 > best) { best = z + 0; out = s " " e " " z } }
                   END { print (out == "" ? "0 0 0" : out) }'
}

plan_layout() {
    P_ROOT_DEV=$(findmnt -no SOURCE /)
    P_ROOT_USED=$(df -B1 --output=used / | tail -1 | tr -d ' ')
    P_ROOT_BYTES=$(lsblk -bdno SIZE "$P_ROOT_DEV")
    local fstype type
    fstype=$(findmnt -no FSTYPE /)
    type=$(lsblk -dno TYPE "$P_ROOT_DEV")

    local target=$(( P_ROOT_USED * (100 + ROOT_HEADROOM_PCT) / 100 ))
    local round=$(( ROOT_ROUND_GIB * GIB ))
    target=$(( (target + round - 1) / round * round ))
    [ "$target" -lt $(( ROOT_FLOOR_GIB * GIB )) ] && target=$(( ROOT_FLOOR_GIB * GIB ))
    [ "$target" -gt "$P_ROOT_BYTES" ] && target=$P_ROOT_BYTES

    P_KIND=unsupported; P_MODE=none
    if [ "$fstype" != "ext4" ]; then
        P_WHY="/ is ${fstype}, not ext4 — repartition by hand"; return 0
    fi

    local shrinkable=0
    case "$type" in
        part)
            P_KIND=part
            P_DISK="/dev/$(lsblk -no PKNAME "$P_ROOT_DEV")"
            read -r P_FREE_START P_FREE_END P_FREE_BYTES < <(largest_free_region "$P_DISK")
            # Shrinking / leaves space right after it: only usable when / is the last partition
            local last
            last=$(lsblk -lnpo NAME,TYPE "$P_DISK" | awk '$2 == "part" { n = $1 } END { print n }')
            [ "$last" = "$P_ROOT_DEV" ] && shrinkable=$(( P_ROOT_BYTES - target ))
            ;;
        lvm)
            P_KIND=lvm
            P_VG=$(sudo lvs --noheadings -o vg_name "$P_ROOT_DEV" | tr -d ' ')
            P_LV=$(sudo lvs --noheadings -o lv_name "$P_ROOT_DEV" | tr -d ' ')
            local pvs
            pvs=$(sudo pvs --noheadings -o pv_name -S "vg_name=${P_VG}" | tr -d ' ')
            if [ "$(wc -l <<< "$pvs")" -ne 1 ] || [ "$(lsblk -dno TYPE "$pvs")" != "part" ]; then
                P_KIND=unsupported; P_WHY="LVM on several PVs or on encryption — repartition by hand"; return 0
            fi
            P_DISK="/dev/$(lsblk -no PKNAME "$pvs")"
            P_FREE_BYTES=$(sudo vgs --noheadings --units b --nosuffix -o vg_free "$P_VG" | tr -d ' ')
            shrinkable=$(( P_ROOT_BYTES - target ))
            ;;
        *)
            P_WHY="/ is on a ${type} device (encrypted?) — repartition by hand"; return 0 ;;
    esac
    P_DISK_BYTES=$(lsblk -bdno SIZE "$P_DISK")

    # Online first: existing free space is enough for a minimum /data
    local cap
    if [ "$P_FREE_BYTES" -ge $(( DATA_MIN_GIB * GIB )) ]; then
        P_MODE=online; P_ROOT_TARGET=$P_ROOT_BYTES; cap=$P_FREE_BYTES
    elif [ $(( P_FREE_BYTES + shrinkable )) -ge $(( DATA_MIN_GIB * GIB )) ]; then
        P_MODE=offline; P_ROOT_TARGET=$target; cap=$(( P_FREE_BYTES + shrinkable ))
        P_WHY="/ has to shrink $(gib_str "$P_ROOT_BYTES") → $(gib_str "$target"); ext4 only shrinks unmounted (live USB)"
    else
        P_WHY="disk too small: / needs $(gib_str "$target"), /data at least ${DATA_MIN_GIB} GiB"
        [ "$P_KIND" = part ] && [ "$shrinkable" -eq 0 ] && [ "$P_ROOT_BYTES" -gt "$target" ] \
            && P_WHY="/ isn't the last partition on ${P_DISK}, and the free space is under ${DATA_MIN_GIB} GiB — repartition by hand"
        return 0
    fi
    # Tiers: 500 GiB if it fits, else 400, else the 250 minimum — UPS keeps the rest for later growth
    local gib
    for gib in "$DATA_IDEAL_GIB" "$DATA_GOOD_GIB" "$DATA_MIN_GIB"; do
        [ "$cap" -ge $(( gib * GIB )) ] && break
    done
    P_DATA_BYTES=$(( gib * GIB ))
    P_UPS_BYTES=$(( cap - P_DATA_BYTES ))
}

plan_summary() {
    echo "/ $(gib_str "$P_ROOT_TARGET") · UPS $(gib_str "$P_UPS_BYTES") · /data $(gib_str "$P_DATA_BYTES")"
}

# set_data_size <GiB> — override /data in the plan (UPS takes the rest); 1 if out of range
set_data_size() {
    local want=$(( $1 * GIB )) cap=$(( P_DATA_BYTES + P_UPS_BYTES ))
    [ "$1" -ge "$DATA_MIN_GIB" ] && [ "$want" -le "$cap" ] || return 1
    P_DATA_BYTES=$want
    P_UPS_BYTES=$(( cap - want ))
}

# create_data_online — make the /data block device from free space; prints its path
create_data_online() {
    local data_gib=$(( P_DATA_BYTES / GIB )) dev
    if [ "$P_KIND" = lvm ]; then
        sudo lvcreate -y -L "${data_gib}G" -n data "$P_VG" >&2
        dev="/dev/${P_VG}/data"
    else
        # /data at the END of the free region, so the gap between / and /data is the UPS reserve
        local table start before
        table=$(sudo parted -m -s "$P_DISK" print | awk -F: 'NR == 2 { print $6 }')
        start=$(( (P_FREE_END + 1 - P_DATA_BYTES + MIB - 1) / MIB * MIB ))
        [ "$start" -lt "$P_FREE_START" ] && start=$(( (P_FREE_START + MIB - 1) / MIB * MIB ))
        before=$(lsblk -lnpo NAME "$P_DISK")
        if [ "$table" = gpt ]; then
            sudo parted -s -a optimal "$P_DISK" unit B mkpart data ext4 "${start}B" "${P_FREE_END}B" >&2
        else
            sudo parted -s -a optimal "$P_DISK" unit B mkpart primary ext4 "${start}B" "${P_FREE_END}B" >&2
        fi
        sudo partprobe "$P_DISK" 2>/dev/null || true
        sudo udevadm settle
        dev=$(comm -13 <(echo "$before") <(lsblk -lnpo NAME "$P_DISK") | head -1)
        [ -b "$dev" ] || die "New partition didn't show up on ${P_DISK} — check: sudo parted ${P_DISK} print"
    fi
    sudo mkfs.ext4 -q -F -L data -m 1 "$dev" >&2
    echo "$dev"
}

# write_offline_script <path> — live-USB script: shrink /, create /data at the end (UPS in between)
write_offline_script() {
    local out="$1" uuid partnum=""
    uuid=$(sudo blkid -s UUID -o value "$P_ROOT_DEV")
    [ "$P_KIND" = part ] && partnum=$(cat "/sys/class/block/$(basename "$P_ROOT_DEV")/partition")
    local table
    table=$(sudo parted -m -s "$P_DISK" print | awk -F: 'NR == 2 { print $6 }')

    sudo tee "$out" >/dev/null <<EOF
#!/bin/bash
# Generated by ledot setup/data.sh on $(hostname), $(date '+%F %T') — run from a LIVE USB, never from the installed system.
#   1. Boot an Ubuntu live USB → open a terminal
#   2. sudo mkdir -p /mnt/efi && sudo mount $(findmnt -no SOURCE /boot/efi 2>/dev/null || echo '<EFI partition>') /mnt/efi
#   3. sudo bash /mnt/efi/ledot/repartition.sh
#   4. Reboot into the system, then: ~/ledot/install.sh data   (finds the "data" partition, mounts it, links ~)
# Plan: / $(gib_str "$P_ROOT_BYTES") → $(gib_str "$P_ROOT_TARGET") · UPS $(gib_str "$P_UPS_BYTES") · /data $(gib_str "$P_DATA_BYTES") (ext4, label "data")
# Partition table before (restore with: sfdisk $P_DISK < this-file's-dir/sfdisk-before.dump):
$(sudo sfdisk -d "$P_DISK" 2>/dev/null | sed 's/^/#   /')

set -euo pipefail
KIND="$P_KIND"; DISK="$P_DISK"; ROOT_UUID="$uuid"; PARTNUM="$partnum"; TABLE="$table"
VG="$P_VG"; LV="$P_LV"
ROOT_GIB=$(( P_ROOT_TARGET / GIB )); DATA_GIB=$(( P_DATA_BYTES / GIB ))

die() { echo "✗ \$*" >&2; exit 1; }
[ "\$(id -u)" -eq 0 ] || die "run with sudo"
[ "\$KIND" = lvm ] && vgchange -ay "\$VG" >/dev/null
ROOT=\$(blkid -U "\$ROOT_UUID") || die "root filesystem (UUID \$ROOT_UUID) not found — wrong machine/disk?"
findmnt -S "\$ROOT" >/dev/null && die "\$ROOT is mounted — boot a live USB first"
[ "\$(blockdev --getsize64 "\$DISK")" = "$P_DISK_BYTES" ] || die "\$DISK isn't the expected disk ($P_DISK_BYTES bytes)"

echo "This will shrink \$ROOT to \${ROOT_GIB} GiB and create a \${DATA_GIB} GiB /data partition at the end of \$DISK."
read -rp "Type YES to continue: " ans; [ "\$ans" = YES ] || die "aborted"
sfdisk -d "\$DISK" > "\$(dirname "\$0")/sfdisk-before.dump"

e2fsck -f -y "\$ROOT" || [ \$? -le 1 ] || die "e2fsck found errors it couldn't fix"
if [ "\$KIND" = lvm ]; then
    lvreduce -y --resizefs -L "\${ROOT_GIB}G" "\$VG/\$LV"
    lvcreate -y -L "\${DATA_GIB}G" -n data "\$VG"
    DATA="/dev/\$VG/data"
else
    resize2fs "\$ROOT" "\${ROOT_GIB}G"
    SECT=\$(blockdev --getss "\$DISK")
    echo ",\$(( ROOT_GIB * 1073741824 / SECT ))" | sfdisk --no-reread -N "\$PARTNUM" "\$DISK"
    partprobe "\$DISK"; udevadm settle
    resize2fs "\$ROOT"   # no-op: fs already fills the shrunk partition exactly
    BEFORE=\$(lsblk -lnpo NAME "\$DISK")
    if [ "\$TABLE" = gpt ]; then NAME=data; else NAME=primary; fi
    parted -s -a optimal "\$DISK" -- mkpart "\$NAME" ext4 "-\${DATA_GIB}GiB" 100%
    partprobe "\$DISK"; udevadm settle
    DATA=\$(comm -13 <(echo "\$BEFORE") <(lsblk -lnpo NAME "\$DISK") | head -1)
fi
[ -b "\$DATA" ] || die "/data partition not found after creating it"
mkfs.ext4 -q -F -L data -m 1 "\$DATA"
e2fsck -f -y "\$ROOT" || [ \$? -le 1 ]
echo "✓ Done: / \${ROOT_GIB} GiB, /data \${DATA_GIB} GiB at \$DATA (label data). Reboot, then: ~/ledot/install.sh data"
EOF
    sudo chmod +x "$out"
}
