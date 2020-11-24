#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/Newifi-D2
	NAME:=Newifi-D2
	PACKAGES:=\
		kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-usb-ledtrig-usbport wpad-mini
endef

define Profile/Newifi-D2/Description
	Package set for Newifi-D2
endef
$(eval $(call Profile,Newifi-D2))
