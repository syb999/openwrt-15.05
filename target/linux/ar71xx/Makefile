#
# Copyright (C) 2008-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

ARCH:=mips
BOARD:=ar71xx
BOARDNAME:=Atheros AR7xxx/AR9xxx
FEATURES:=mips16 rtc
CPU_TYPE=34kc
SUBTARGETS:=generic nand mikrotik

KERNEL_PATCHVER:=3.18

include $(INCLUDE_DIR)/target.mk

DEFAULT_PACKAGES += \
	kmod-gpio-button-hotplug swconfig \
	kmod-ath9k wpad-mini uboot-envtools

$(eval $(call BuildTarget))
