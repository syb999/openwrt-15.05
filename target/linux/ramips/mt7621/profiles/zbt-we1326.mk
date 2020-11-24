#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/ZBT-WE1326
	NAME:=ZBT-WE1326
	PACKAGES:=\
		kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-sdhci-mt7620 wpad-mini
endef

define Profile/ZBT-WE1326/Description
	Package set for ZBT-WE1326
endef
$(eval $(call Profile,ZBT-WE1326))
