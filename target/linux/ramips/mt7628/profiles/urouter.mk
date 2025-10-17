#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/UROUTER
	NAME:=BHU uRouter
	PACKAGES:=\
		kmod-usb-core kmod-usb-dwc2 kmod-usb2 kmod-usb-ohci \
		kmod-mt7603
endef

define Profile/UROUTER/Description
 Support for BHU uRouter routers
endef
$(eval $(call Profile,UROUTER))
