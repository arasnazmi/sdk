#!/usr/bin/env bash
# encrypt-image.sh — wrap the rootfs partition of a Gemstone image with LUKS.
#
# Usage:
#   sudo ./encrypt-image.sh <image-file>
#
# Image layout (from distro/distro.yaml):
#   p1: BOOT/efi  (vfat)                       — left untouched
#   p2: root      (btrfs on ARM, ext4 on amd64) — converted to LUKS
#
# Default passphrase is 4380 (override via LUKS_PASSPHRASE env var).

set -euo pipefail

readonly MAPPER_NAME="gem_luks_root"
readonly REQUIRED_TOOLS=(losetup cryptsetup blkid rsync partprobe udevadm wipefs awk)

PASSPHRASE="${LUKS_PASSPHRASE:-4380}"
IMG=""
LOOP=""
ROOT_PART=""
FS_TYPE=""
MNT_PLAIN=""
MNT_LUKS=""
BACKUP_DIR=""

log() {
    echo "==> $*";
}

die() {
    echo "Error: $*" >&2;
    exit 1;
}

usage() {
    cat >&2 <<EOF
Usage: $0 <image-file>
  LUKS_PASSPHRASE env var overrides default passphrase ($PASSPHRASE).
EOF
    exit 1
}

# Idiomatic trap handler: chained guards keep the cleanup compact and
# tolerant of partially-completed runs.
cleanup() {
    set +e
    [ -n "$MNT_PLAIN" ] && mountpoint -q "$MNT_PLAIN" && umount "$MNT_PLAIN"
    [ -n "$MNT_LUKS"  ] && mountpoint -q "$MNT_LUKS"  && umount "$MNT_LUKS"
    [ -e "/dev/mapper/$MAPPER_NAME" ] && cryptsetup close "$MAPPER_NAME"
    [ -n "$LOOP" ] && losetup "$LOOP" >/dev/null 2>&1 && losetup -d "$LOOP"
    [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ] && rm -rf "$BACKUP_DIR"
    [ -n "$MNT_PLAIN"  ] && [ -d "$MNT_PLAIN"  ] && rmdir "$MNT_PLAIN"  2>/dev/null
    [ -n "$MNT_LUKS"   ] && [ -d "$MNT_LUKS"   ] && rmdir "$MNT_LUKS"   2>/dev/null
}

# ---------- steps ----------

validate_inputs() {
    if [ -z "$IMG" ];                     then usage;                           fi
    if [ ! -f "$IMG" ];                   then die "Image not found: $IMG";     fi
    if [ "$EUID" -ne 0 ];                 then die "Run as root (sudo).";       fi
    for bin in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$bin" >/dev/null; then die "Missing tool: $bin";       fi
    done
}

attach_loop_device() {
    log "Attaching loop device for $IMG"
    LOOP=$(losetup --find --show --partscan "$IMG")
    partprobe "$LOOP" 2>/dev/null || true
    udevadm settle

    ROOT_PART="${LOOP}p2"
    if [ ! -b "$ROOT_PART" ]; then
        die "Rootfs partition $ROOT_PART not found."
    fi

    FS_TYPE=$(blkid -o value -s TYPE "$ROOT_PART" || true)
    case "$FS_TYPE" in
        btrfs|ext4) ;;
        *) die "Unsupported rootfs filesystem '$FS_TYPE' (expected btrfs or ext4)." ;;
    esac
    log "Rootfs partition: $ROOT_PART ($FS_TYPE)"
}

backup_rootfs() {
    MNT_PLAIN=$(mktemp -d)
    BACKUP_DIR=$(mktemp -d -t gem-rootfs-XXXX)

    log "Backing up rootfs contents to $BACKUP_DIR"
    mount "$ROOT_PART" "$MNT_PLAIN"
    rsync -aHAX --numeric-ids --sparse "$MNT_PLAIN/" "$BACKUP_DIR/"
    umount "$MNT_PLAIN"
}

create_luks_container() {
    log "Wiping existing filesystem signatures on $ROOT_PART"
    wipefs -af "$ROOT_PART"

    log "Creating LUKS2 container (passphrase: $PASSPHRASE)"
    printf '%s' "$PASSPHRASE" | cryptsetup luksFormat \
        --type luks2 \
        --batch-mode \
        --pbkdf argon2id \
        --iter-time 2000 \
        --key-file=- \
        "$ROOT_PART"

    log "Opening LUKS container as /dev/mapper/$MAPPER_NAME"
    printf '%s' "$PASSPHRASE" | cryptsetup open --key-file=- "$ROOT_PART" "$MAPPER_NAME"
}

create_filesystem() {
    log "Recreating $FS_TYPE filesystem inside the LUKS container"
    case "$FS_TYPE" in
        btrfs) mkfs.btrfs -f -L gem-root "/dev/mapper/$MAPPER_NAME" ;;
        ext4)  mkfs.ext4  -F -L gem-root "/dev/mapper/$MAPPER_NAME" ;;
    esac
}

restore_rootfs() {
    MNT_LUKS=$(mktemp -d)
    log "Restoring rootfs contents into encrypted volume"
    mount "/dev/mapper/$MAPPER_NAME" "$MNT_LUKS"
    rsync -aHAX --numeric-ids --sparse "$BACKUP_DIR/" "$MNT_LUKS/"
}

# debos wrote /etc/fstab with the original (pre-LUKS) UUID. mkfs above
# created a brand new filesystem with a different UUID, so without this
# rewrite systemd-remount-fs fails on every boot with
#   "mount: /: can't find UUID=..."
update_fstab_uuid() {
    local new_uuid
    new_uuid=$(blkid -o value -s UUID "/dev/mapper/$MAPPER_NAME")
    if [ -z "$new_uuid" ]; then
        die "Failed to read new rootfs UUID"
    fi

    log "Updating /etc/fstab root UUID to $new_uuid"
    awk -v u="$new_uuid" '
        $2 == "/" && $1 ~ /^UUID=/ { sub(/^UUID=[^ \t]+/, "UUID=" u) }
        { print }
    ' "$MNT_LUKS/etc/fstab" > "$MNT_LUKS/etc/fstab.new"
    mv "$MNT_LUKS/etc/fstab.new" "$MNT_LUKS/etc/fstab"
}

close_luks_container() {
    sync
    umount "$MNT_LUKS"
    log "Closing LUKS container"
    cryptsetup close "$MAPPER_NAME"
}

print_summary() {
    cat <<EOF

Done. $IMG rootfs (p2) is now LUKS-encrypted.
  Passphrase: $PASSPHRASE
  UUID: $(blkid -o value -s UUID "$ROOT_PART")
EOF
}

# ---------- main ----------

main() {
    IMG="${1:-}"
    trap cleanup EXIT INT TERM

    validate_inputs
    attach_loop_device
    backup_rootfs
    create_luks_container
    create_filesystem
    restore_rootfs
    update_fstab_uuid
    close_luks_container
    print_summary
}

main "$@"
