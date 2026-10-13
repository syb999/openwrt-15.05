#!/bin/sh
# flash-uboot.sh - flash a CN6619 (ZM-WR2500) U-Boot image to the protected
#                  "u-boot" partition (mtd0).
#
# The u-boot partition on this board is READ-ONLY.  This script therefore
#   1. loads kmod-mtd-rw (i_want_a_brick=1) to make read-only MTD partitions
#      writable, then calls "mtd unlock u-boot"
#   2. backs up the current U-Boot
#   3. writes the image
#   4. reads it back and compares the MD5
#
# Usage:  flash-uboot.sh [image] [--yes]
#   image   path to the u-boot image (default /root/uboot_cn6619.bin)
#           The image is NOT part of the firmware; copy it over first, e.g.
#           scp bin/u-boot_mod__zmtel_zm-wr2500__*.bin root@<dev>:/root/uboot_cn6619.bin
#
# WARNING: flashing U-Boot is the riskiest operation on this device.  If the
# read-back verify fails, DO NOT reboot - restore the backup (printed below)
# while still in Linux, or use the serial u-boot console.

IMG="${1:-/root/uboot_cn6619.bin}"
MTD_PART="u-boot"
MTD_DEV="/dev/mtd0"
BACKUP="/root/uboot_OLD.bin"
CONFIRM=1

for a in "$@"; do
	[ "$a" = "--yes" ] && CONFIRM=0
done

[ -f "$IMG" ] || { echo "ERROR: image not found: $IMG"; exit 1; }
[ -c "$MTD_DEV" ] || { echo "ERROR: $MTD_DEV not found"; exit 1; }

# partition size from /proc/mtd ("u-boot")
PART_HEX=$(awk -v p="$MTD_PART" '$0 ~ ("\"" p "\"") {print $2; exit}' /proc/mtd)
[ -n "$PART_HEX" ] || { echo "ERROR: partition '$MTD_PART' not in /proc/mtd"; exit 1; }
PSIZE=$((0x$PART_HEX))
SIZE=$(wc -c < "$IMG")

echo "U-Boot image : $IMG ($SIZE bytes)"
echo "Target       : $MTD_DEV  partition '$MTD_PART' ($PSIZE bytes)"
md5sum "$IMG"

if [ "$SIZE" != "$PSIZE" ]; then
	echo "ERROR: image size $SIZE != partition size $PSIZE - refusing"
	exit 1
fi

if [ "$CONFIRM" = "1" ]; then
	printf 'Flash U-Boot now? This is risky and can brick the device! [y/N] '
	read a
	case "$a" in y|Y) ;; *) echo "aborted"; exit 0;; esac
fi

# 1) unlock the read-only partition
echo "[1/5] making the '$MTD_PART' partition writable ..."
if ! lsmod | grep -q '^mtd_rw'; then
	modprobe mtd-rw i_want_a_brick=1 2>/dev/null || \
		insmod mtd-rw i_want_a_brick=1 2>/dev/null
fi
lsmod | grep -q '^mtd_rw' || echo "  WARN: mtd-rw module not loaded (kmod-mtd-rw missing?)"
mtd unlock "$MTD_PART" 2>/dev/null && echo "  unlocked" || echo "  (mtd unlock returned non-zero)"

# 2) backup
echo "[2/5] backing up current U-Boot to $BACKUP ..."
dd if=$MTD_DEV of=$BACKUP 2>/dev/null
BK=$(md5sum "$BACKUP" | cut -d' ' -f1)
echo "  backup md5: $BK"

# 3) write
echo "[3/5] writing ..."
mtd write "$IMG" "$MTD_PART" || { echo "ERROR: write failed"; exit 1; }

# 4) verify
echo "[4/5] verifying read-back ..."
CHK=$(dd if=$MTD_DEV bs=1 count=$PSIZE 2>/dev/null | md5sum | cut -d' ' -f1)
NEW=$(md5sum "$IMG" | cut -d' ' -f1)

if [ "$CHK" = "$NEW" ]; then
	echo "[5/5] OK: U-Boot written and verified ($NEW)"
	echo "Now run:  reboot"
else
	echo "[5/5] *** MISMATCH ***  read-back $CHK != $NEW"
	echo "DO NOT REBOOT.  Restore now with:"
	echo "    cp $BACKUP /tmp/ub_restore.bin"
	echo "    mtd write /tmp/ub_restore.bin u-boot"
	exit 1
fi
