#!/usr/bin/env bash
# encrypt-image.sh — wrap the rootfs partition of a Gemstone image with LUKS.
#
# Usage:
#   sudo ./encrypt-image.sh <image-file>
#
# The image layout is described in distro/distro.yaml:
#   - p1: BOOT/efi  (vfat) — left untouched
#   - p2: root      (btrfs on ARM, ext4 on amd64) — converted to LUKS
#
# Default passphrase is 4380 (override via LUKS_PASSPHRASE env var).

set -euo pipefail

IMG="${1:-}"
PASSPHRASE="${LUKS_PASSPHRASE:-4380}"
MAPPER_NAME="gem_luks_root"

LOOP=""
MNT_PLAIN=""
MNT_LUKS=""
BACKUP_DIR=""

usage() {
    echo "Usage: $0 <image-file>" >&2
    echo "  LUKS_PASSPHRASE env var overrides default passphrase ($PASSPHRASE)." >&2
    exit 1
}

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
trap cleanup EXIT INT TERM

[ -z "$IMG" ]    && usage
[ ! -f "$IMG" ]  && { echo "Image not found: $IMG" >&2; exit 1; }
[ "$EUID" -ne 0 ] && { echo "Run as root (sudo)." >&2; exit 1; }

for bin in losetup cryptsetup blkid rsync partprobe udevadm; do
    command -v "$bin" >/dev/null || { echo "Missing tool: $bin" >&2; exit 1; }
done

echo "==> Attaching loop device for $IMG"
LOOP=$(losetup --find --show --partscan "$IMG")
partprobe "$LOOP" 2>/dev/null || true
udevadm settle

ROOT_PART="${LOOP}p2"
[ -b "$ROOT_PART" ] || { echo "Rootfs partition $ROOT_PART not found." >&2; exit 1; }

FS_TYPE=$(blkid -o value -s TYPE "$ROOT_PART" || true)
case "$FS_TYPE" in
    btrfs|ext4) ;;
    *) echo "Unsupported rootfs filesystem '$FS_TYPE' (expected btrfs or ext4)." >&2; exit 1 ;;
esac
echo "==> Rootfs partition: $ROOT_PART ($FS_TYPE)"

MNT_PLAIN=$(mktemp -d)
BACKUP_DIR=$(mktemp -d -t gem-rootfs-XXXX)
MNT_LUKS=$(mktemp -d)

echo "==> Backing up rootfs contents to $BACKUP_DIR"
mount "$ROOT_PART" "$MNT_PLAIN"
rsync -aHAX --numeric-ids --sparse "$MNT_PLAIN/" "$BACKUP_DIR/"
umount "$MNT_PLAIN"

echo "==> Wiping any existing filesystem signatures on $ROOT_PART"
wipefs -af "$ROOT_PART"

echo "==> Creating LUKS2 container (passphrase: $PASSPHRASE)"
printf '%s' "$PASSPHRASE" | cryptsetup luksFormat \
    --type luks2 \
    --batch-mode \
    --pbkdf argon2id \
    --iter-time 2000 \
    --key-file=- \
    "$ROOT_PART"

echo "==> Opening LUKS container as /dev/mapper/$MAPPER_NAME"
printf '%s' "$PASSPHRASE" | cryptsetup open --key-file=- "$ROOT_PART" "$MAPPER_NAME"

echo "==> Recreating $FS_TYPE filesystem inside the LUKS container"
case "$FS_TYPE" in
    btrfs) mkfs.btrfs -f -L gem-root "/dev/mapper/$MAPPER_NAME" ;;
    ext4)  mkfs.ext4  -F -L gem-root "/dev/mapper/$MAPPER_NAME" ;;
esac

echo "==> Restoring rootfs contents into encrypted volume"
mount "/dev/mapper/$MAPPER_NAME" "$MNT_LUKS"
rsync -aHAX --numeric-ids --sparse "$BACKUP_DIR/" "$MNT_LUKS/"
sync
umount "$MNT_LUKS"

echo "==> Closing LUKS container"
cryptsetup close "$MAPPER_NAME"

echo
echo "Done. $IMG rootfs (p2) is now LUKS-encrypted."
echo "  Passphrase: $PASSPHRASE"
echo "  UUID: $(blkid -o value -s UUID "$ROOT_PART")"
