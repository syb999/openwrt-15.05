#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/YTXC-OEM-AP
	NAME:=YTXC OEM AP
	PACKAGES:=\
		kmod-usb-core kmod-usb-dwc2 kmod-usb2 kmod-usb-ohci \
		kmod-mt7603 panel-ap-setup
endef

define Profile/YTXC-OEM-AP/Description
 Support for YTXC OEM Panel AP.
endef
$(eval $(call Profile,YTXC-OEM-AP))
