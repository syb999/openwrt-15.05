#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/JDCloud-1
	NAME:=JDCloud-1
	PACKAGES:=\
		kmod-usb-core kmod-usb3 kmod-usb-hid kmod-sdhci-mt7620 \
		kmod-ledtrig-usbdev kmod-mt7603 \
		kmod-mt7615e wpad-mini
endef

define Profile/JDCloud-1/Description
	Package set for JDCloud-1
endef
$(eval $(call Profile,JDCloud-1))
