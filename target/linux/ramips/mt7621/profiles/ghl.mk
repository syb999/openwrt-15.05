#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/GHL
	NAME:=GHL-R-001
	PACKAGES:=\
		kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-usb-ledtrig-usbport wpad-mini
endef

define Profile/GHL/Description
 Support for GHL routers
endef
$(eval $(call Profile,GHL))
