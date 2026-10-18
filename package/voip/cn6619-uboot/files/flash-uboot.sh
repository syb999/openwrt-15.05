#!/bin/sh
# flash-uboot.sh - 刷 CN6619 / ZM-WR2500 的 U-Boot（u-boot_mod）到 u-boot 分区(mtd0)
#
# 通刷镜像（编程器 / mtd / 网页 三种方式通用）:
#   u-boot_mod__zmtel_zm-wr2500__131072B.bin
#   131072 字节  md5 ab22e73682ac8410e1091699e57d54e2
#
# 流程: 解锁只读分区 -> 备份当前 U-Boot -> 写入(小于分区自动 0xFF 补齐) -> 回读比对
#
# 用法:
#   flash-uboot.sh [镜像] [--yes]     默认镜像 /root/uboot_cn6619.bin
#   flash-uboot.sh --restore [--yes]  把 /root/uboot_OLD.bin 写回(救砖)
#
# WARNING: 刷 U-Boot 是本设备最高风险操作。回读校验失败时千万不要重启,
#          立刻 --restore 写回, 或走串口 u-boot 控制台。

IMG="/root/uboot_cn6619.bin"
RESTORE=0
MTD_PART="u-boot"
MTD_DEV="/dev/mtd0"
BACKUP="/root/uboot_OLD.bin"
CONFIRM=1
NEW="/tmp/uboot_flash.$$.bin"

for a in "$@"; do
	case "$a" in
	--yes)      CONFIRM=0 ;;
	--restore)  RESTORE=1 ;;
	-*)         echo "unknown option: $a"; exit 1 ;;
	*)          IMG="$a" ;;
	esac
done

[ -c "$MTD_DEV" ] || { echo "ERROR: $MTD_DEV not found"; exit 1; }

PART_HEX=$(awk -v p="$MTD_PART" '$0 ~ ("\"" p "\"") {print $2; exit}' /proc/mtd)
[ -n "$PART_HEX" ] || { echo "ERROR: partition '$MTD_PART' not in /proc/mtd"; exit 1; }
PSIZE=$((0x$PART_HEX))

if [ "$RESTORE" = "1" ]; then
	IMG="$BACKUP"
	[ -f "$IMG" ] || { echo "ERROR: 没有备份文件 $BACKUP"; exit 1; }
fi

[ -f "$IMG" ] || { echo "ERROR: image not found: $IMG"; exit 1; }
SIZE=$(wc -c < "$IMG")

echo "U-Boot image : $IMG ($SIZE bytes)"
echo "Target       : $MTD_DEV  partition '$MTD_PART' ($PSIZE bytes)"
md5sum "$IMG"

if [ "$SIZE" -gt "$PSIZE" ]; then
	echo "ERROR: 镜像 $SIZE > 分区 $PSIZE, 拒绝"
	exit 1
fi

# 小于分区时补 0xFF(与擦除态一致), 否则尾部会残留旧 u-boot 环境
if [ "$SIZE" -lt "$PSIZE" ]; then
	echo "  镜像比分区小 $((PSIZE-SIZE)) 字节 -> 用 0xFF 补齐"
	cat "$IMG" > "$NEW"
	dd if=/dev/zero bs=1 count=$((PSIZE-SIZE)) 2>/dev/null | tr '\000' '\377' >> "$NEW"
	IMG="$NEW"
fi

if [ "$CONFIRM" = "1" ]; then
	printf 'Flash U-Boot now? This is risky and can brick the device! [y/N] '
	read an
	case "$an" in y|Y) ;; *) echo "aborted"; rm -f "$NEW"; exit 0;; esac
fi

echo "[1/5] 解锁只读分区 ..."
if ! lsmod | grep -q '^mtd_rw'; then
	modprobe mtd-rw i_want_a_brick=1 2>/dev/null || \
		insmod /tmp/mtd-rw-3.3.8.ko mtdname=u-boot i_want_a_brick=1 2>/dev/null
fi
lsmod | grep -q '^mtd_rw' || echo "  WARN: mtd-rw 未加载 (需要 kmod-mtd-rw 或 /tmp/mtd-rw-3.3.8.ko)"
mtd unlock "$MTD_PART" 2>/dev/null && echo "  unlocked" || echo "  (mtd unlock 返回非 0)"

if [ "$RESTORE" = "0" ]; then
	echo "[2/5] 备份当前 U-Boot -> $BACKUP ..."
	dd if=$MTD_DEV of=$BACKUP 2>/dev/null
	echo "  backup md5: $(md5sum "$BACKUP" | cut -d' ' -f1)"
else
	echo "[2/5] 恢复模式: 直接写回 $BACKUP"
fi

echo "[3/5] 写入 ..."
mtd write "$IMG" "$MTD_PART" || { echo "ERROR: write failed"; rm -f "$NEW"; exit 1; }

echo "[4/5] 回读校验 ..."
CHK=$(dd if=$MTD_DEV 2>/dev/null | md5sum | cut -d' ' -f1)
NEWM=$(md5sum "$IMG" | cut -d' ' -f1)
rm -f "$NEW"

if [ "$CHK" = "$NEWM" ]; then
	echo "[5/5] OK: U-Boot 写入并校验通过 ($NEWM)"
	echo "现在执行:  reboot"
else
	echo "[5/5] *** 校验不一致 ***  回读 $CHK != 期望 $NEWM"
	echo "千万不要重启!  立刻恢复:"
	echo "    /usr/sbin/flash-uboot.sh --restore --yes"
	exit 1
fi
