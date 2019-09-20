#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

ARCH:=mipsel
BOARD:=siflower
BOARDNAME:=MIPS Siflower SF16ax8 board
SUBTARGETS:=sf16a18-fullmask
INITRAMFS_EXTRA_FILES:=
MAINTAINER:=Shanghai Siflower Communication Technology Co., Ltd.

KERNEL_PATCHVER:=3.18

include $(INCLUDE_DIR)/target.mk

DEFAULT_PACKAGES += wpad-mini

define Target/Description
	Build firmware images for Siflower based boards.
endef

$(eval $(call BuildTarget))
