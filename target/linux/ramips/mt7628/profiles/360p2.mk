#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/360P2
	NAME:=360 P2
	PACKAGES:=\
		kmod-usb-core kmod-usb-dwc2 kmod-usb2 kmod-usb-ohci \
		kmod-mt76x2 kmod-mt7603 uboot-envtools
endef

define Profile/360P2/Description
 Support for 360P2 routers
endef
$(eval $(call Profile,360P2))
