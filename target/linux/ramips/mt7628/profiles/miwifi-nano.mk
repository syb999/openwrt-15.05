#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/MIWIFI-NANO
	NAME:=MiWiFi Nano
	PACKAGES:=\
		kmod-usb-core kmod-usb2 kmod-usb-ohci \
		kmod-mt7603 kmod-ledtrig-usbdev uboot-envtools
endef

define Profile/MIWIFI-NANO/Description
 Support for miwifi-nano routers
endef
$(eval $(call Profile,MIWIFI-NANO))
