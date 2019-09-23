#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/Newifi-D1
	NAME:=Newifi-D1
	PACKAGES:=\
		kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-usb-ledtrig-usbport wpad-mini \
		kmod-ledtrig-usbdev kmod-sdhci-mt7620
endef

define Profile/Newifi-D1/Description
	Package set for Newifi-D1
endef

$(eval $(call Profile,Newifi-D1))
