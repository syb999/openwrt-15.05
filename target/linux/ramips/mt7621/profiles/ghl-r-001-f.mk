#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/GHL-R-001-F
	NAME:=GHL-R-001-F
	PACKAGES:=\
		kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-usb-ledtrig-usbport wpad-mini
endef

define Profile/GHL-R-001-F/Description
 Support for GHL-R-001-F routers
endef
$(eval $(call Profile,GHL-R-001-F))
