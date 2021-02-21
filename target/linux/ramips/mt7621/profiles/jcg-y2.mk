#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/JCG-Y2
	NAME:=JCG-Y2
	PACKAGES:=\
		kmod-mt7615e kmod-usb3 kmod-usb-ledtrig-usbport wpad-mini \
		kmod-ledtrig-usbdev mt7615-dbdc-setup
endef

define Profile/JCG-Y2/Description
	Package set for JCG-Y2
endef

$(eval $(call Profile,JCG-Y2))
