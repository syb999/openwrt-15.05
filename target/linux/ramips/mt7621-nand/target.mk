#
# Copyright (C) 2009 OpenWrt.org
#

SUBTARGET:=mt7621-nand
BOARDNAME:=MT7621 NAND flash based boards
ARCH_PACKAGES:=ramips_1004kc
FEATURES+=usb squashfs nand ubifs ramdisk
CPU_TYPE:=1004kc
CPU_SUBTYPE:=dsp
CFLAGS:=-Os -pipe -mmt -mips32r2 -mtune=1004kc

DEFAULT_PACKAGES += 

define Target/Description
	Build firmware images for Ralink MT7621 with nand flash based boards.
endef
