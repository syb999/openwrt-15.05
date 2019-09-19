#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/DAISHUYUN
 NAME:=Daishuyun
 PACKAGES:=\
	kmod-usb-core kmod-usb-dwc2 kmod-usb2 kmod-usb-ohci \
	kmod-mt76 kmod-sdhci-mt7620
endef

define Profile/DAISHUYUN/Description
 Support for DAISHUYUN routers
endef
$(eval $(call Profile,DAISHUYUN))
